#
# Copyright 2007-2010 David Snopek <dsnopek@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package POE::Component::MessageQueue::Storage::FileSystem;
use Moose;

use POE::Kernel;
use POE::Session;
use POE::Filter::Stream;
use POE::Wheel::ReadWrite;
use IO::File;
use IO::Dir;

use constant NotFound => 'FILESYSTEM: Message not on disk';

has 'info_storage' => (
	is       => 'ro',
	required => 1,	
	does     => qw(POE::Component::MessageQueue::Storage),
	handles  => [qw(claim disown_all disown_destination)],
);

# For all these, we get an aref of stuff that needs bodies from our info
# store.  So, let's just make them all at once.  
foreach my $method (qw(get get_all)) {
	__PACKAGE__->meta->add_method($method, sub {
		my $self = shift;
		my $callback = pop;
		$self->info_storage->$method(@_, sub {
			$self->_read_loop($_[0], [], sub {
				@_ = ([grep { $_ ne NotFound } @{$_[0]}]);
				goto $callback;
			});
		});
	});
}

# These are similar to the above, but for single messages.  Also, we want to
# retry if the message info tells us about is not on disk.
foreach my $method (qw(get_oldest claim_and_retrieve)) {
	__PACKAGE__->meta->add_method($method, sub {
		my $self = shift;
		my $callback = pop;
		my @args = @_;
		$self->info_storage->$method(@args, sub {
			my $info_answer = $_[0];
			goto $callback unless $info_answer;

			$self->_read_loop([$info_answer], [], sub {
				my $disk_answer = $_[0]->[0];

				if ($disk_answer eq NotFound) 
				{
					$self->$method(@args, $callback);
				}
				else
				{
					@_ = ($disk_answer);
					goto $callback;
				}
			});
		});
	});
}

# Apply the role here, after we've monkeyed with the metaclass
with qw(POE::Component::MessageQueue::Storage);

has 'data_dir' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

use constant empty_hashref => (
	is       => 'ro',
	default  => sub{ {} },
);

has 'file_wheels'          => empty_hashref;
has 'wheel_to_message_map' => empty_hashref;
has 'pending_writes'       => empty_hashref;

has 'alias' => (
	is       => 'ro',
	isa      => 'Str',
	default  => 'MQ-Storage-Filesystem',
	required => 1,
);

has 'session' => (is => 'rw');

has 'shutdown_callback' => (
	is        => 'ro',
	writer    => 'set_shutdown_callback',
	predicate => 'shutting_down',
	clearer   => 'stop_shutdown',
);

has 'shutdown_waiting' => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
);

after 'set_logger' => sub {
	my ($self, $logger) = @_;
	$self->info_storage->set_logger($logger);
};

sub BUILD 
{
	my $self = shift;
	$self->children({INFO => $self->info_storage});
	$self->session(POE::Session->create(
		object_states => [
			$self => [qw(
				_start                   _stop                 _shutdown
				_read_message_from_disk  _read_input           _read_error  
				_write_message_to_disk   _write_flushed_event
			)]
		],
	));
}

sub _start
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	$kernel->alias_set($self->alias);
}

sub _shutdown
{
	my ($self, $kernel) = @_[OBJECT, KERNEL];
	$kernel->alias_remove($self->alias);
}

# POE calls this when the session dies.
sub _stop
{
	my ($self) = $_[OBJECT];
	$self->_something_finished_shutting();
}

sub _something_finished_shutting {
	my $self     = $_[0];
	my $complete = $self->shutdown_callback;

	if($self->shutdown_waiting) 
	{
		$self->shutdown_waiting(0);
	}
	else 
	{
		goto $complete if $complete;
	}
}

sub storage_shutdown
{
	my ($self, $complete) = @_;

	# We need to wait for two states: info_storage complete and no wheels.
	$self->set_shutdown_callback($complete);

	$self->info_storage->storage_shutdown(sub { 
		$self->_something_finished_shutting();
	});

	$poe_kernel->post($self->alias, '_shutdown');
}

sub store
{
	my ($self, $message, $callback) = @_;

	# DRS: To avaid a race condition where:
	#
	#  (1) We post _write_message_to_disk
	#  (2) Message is "removed" from disk (even though it isn't there yet)
	#  (3) We start writing message to disk
	#
	# Mark message as needing to be written.
	# 
	# PLD: Also, multiple copies of messages is bad juju.  Delete the body from
	#      a clone.
	my $info_copy = $message->clone;

	# Make sure the size is computed before we delete the body
	$info_copy->size;
	$self->pending_writes->{$message->id} = $info_copy->delete_body();

	# initiate file writing process (only the body will be written)
	$poe_kernel->post($self->session, _write_message_to_disk => $message);

	$self->info_storage->store($info_copy, $callback);
}

sub _get_filename
{
	my ($self, $message_id) = @_;
	return sprintf('%s/msg-%s.txt', $self->data_dir, $message_id);
}

sub _hard_delete
{
	my ($self, $id) = @_; 
	
	# Just unlink it unless there are pending writes
	return $self->_unlink_file($id) unless delete $self->pending_writes->{$id};

	my $info = $self->file_wheels->{$id};
	if ($info) 
	{
		$self->log('debug', "Stopping wheels for message $id (removing)");
		my $wheel = $info->{write_wheel} || $info->{read_wheel};
		$wheel->shutdown_input();
		$wheel->shutdown_output();

		# Mark for deletion: we'll detect this primarly in 
		# _write_flushed_event and unlink the file at that time 
		# (prevents a file descriptor leak)
		$info->{delete_me} = 1;
	}
	else
	{
		# If we haven't started yet, _write_message_to_disk will just abort.
		$self->log('debug', "Removing message $id before writing started");
	}
}

sub _unlink_file
{
	my ($self, $message_id) = @_;
	my $fn = $self->_get_filename($message_id);
	$self->log( 'debug', "Deleting $fn" );
	unlink $fn || 
		$self->log( 'error', "Unable to remove $fn: $!" );
	return;
}

# We can't use an iterative loop, because we may have to read messages from
# disk.  So, here's our recursive function that may pause in the middle to
# wait for disk reads.
sub _read_loop
{
	my ($self, $to_read, $done_reading, $callback) = @_;
	my $again = sub { 
		@_ = ($self, $to_read, $done_reading, $callback); 
		goto &_read_loop;
	};

	my $message = pop(@$to_read);
	unless ($message) {
		@_ = ($done_reading);
		goto $callback;
	}

	if (my $body = $self->pending_writes->{$message->id}) 
	{
		$message->body($body);
		push(@$done_reading, $message);
		goto $again;
	}
	else
	{
		# Don't have the body anymore, so we'll have to read it from disk.
		$poe_kernel->post($self->session, 
			_read_message_from_disk => $message->id, sub {
				my $answer = $_[0];
				if ($answer eq NotFound) 
				{
					push(@$done_reading, $answer);
				}
				elsif (defined $answer)
				{
					$message->body($answer);
					push(@$done_reading, $message);
				}
				goto $again;
			}
		);
	}
}

sub remove
{
	my ($self, $message_ids, $callback) = @_;
	$self->info_storage->remove($message_ids, sub {
		$self->_hard_delete($_) foreach (@$message_ids);
		goto $callback if $callback;
	});
}

sub empty
{
	my ($self, $callback) = @_;

	$self->info_storage->empty(sub {
		# Delete all the message files that don't have writes pending
		my $dh = IO::Dir->new($self->data_dir);
		foreach my $fn ($dh->read())
		{
			if ($fn =~ /msg-\(.*\)\.txt/)
			{
				my $id = $1;
				$self->_unlink_file($id) unless exists $self->pending_writes->{$id};	
			}
		}
	
		# Do the special dance for deleting those that are pending
		$self->_hard_delete($_) foreach (keys %{$self->pending_writes});
		goto $callback if $callback;
	});
}

#
# For handling disk access
#
sub _write_message_to_disk
{
	my ($self, $kernel, $message) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

	if ($self->file_wheels->{$message->id})
	{
		$self->log('emergency', sprintf(
			'%s::_write_message_to_disk: wheel already exists for message %s!',
			__PACKAGE__, $message->id
		));
		return;
	}
	 
	unless ($self->pending_writes->{$message->id})
	{
		$self->log('debug', sprintf('Abort write of message %s to disk',
			$message->id));
		delete $self->file_wheels->{$message->id};
		return;
	}

	# Yes, we do want to die if we can't open the file for writing.  It
	# means something is wrong and it's very unlikely we can persist other
	# messages.
	my $fn = $self->_get_filename($message->id);
	my $fh = IO::File->new( ">$fn" ) || die "Unable to save message in $fn: $!";

	my $wheel = POE::Wheel::ReadWrite->new(
		Handle       => $fh,
		Filter       => POE::Filter::Stream->new(),
		FlushedEvent => '_write_flushed_event'
	);

	# initiate the write to disk
	$wheel->put($self->pending_writes->{$message->id});

	# stash the wheel in our maps
	$self->file_wheels->{$message->id} = {write_wheel => $wheel};

	$self->wheel_to_message_map->{$wheel->ID()} = $message->id;
}

sub _read_message_from_disk
{
	my ($self, $kernel, $id, $callback) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

	if ($self->file_wheels->{$id})
	{
		my $here = __PACKAGE__.'::_read_message_from_disk()';
		$self->log('emergency',
			"$here: A wheel already exists for this message ($id)! ".
			'This should never happen!'
		);
		return;
	}

	my $fn = $self->_get_filename($id);
	my $fh = IO::File->new( $fn );
	
	$self->log( 'debug', "Starting to read $fn from disk" );

	# if we can't find the message body.  This usually happens as a result
	# of crash recovery.
	unless ($fh)
	{
		$self->log( 'warning', "Can't find $fn on disk!  Discarding message." );

		# we need to get the message out of the info store
		$self->info_storage->remove($id);

		@_ = (NotFound);
		goto $callback;
	}
	
	# setup the wheel
	my $wheel = POE::Wheel::ReadWrite->new(
		Handle       => $fh,
		Filter       => POE::Filter::Stream->new(),
		InputEvent   => '_read_input',
		ErrorEvent   => '_read_error'
	);

	# stash the wheel in our maps
	$self->file_wheels->{$id} = {
		read_wheel  => $wheel,
		accumulator => q{},
		callback    => $callback
	};
	$self->wheel_to_message_map->{$wheel->ID()} = $id;
}

sub _read_input
{
	my ($self, $kernel, $input, $wheel_id) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

	# We do care about reading during shutdown! Maybe.  We may be using this as
	# a front-store (HA!), and doing empty.

	my $id = $self->wheel_to_message_map->{$wheel_id};
	$self->file_wheels->{$id}->{accumulator} .= $input;	
}

sub _read_error
{
	my ($self, $op, $errnum, $errstr, $wheel_id) = @_[ OBJECT, ARG0..ARG3 ];

	if ( $op eq 'read' and $errnum == 0 )
	{
		# EOF!  Our message is now totally assembled.  Hurray!

		my $id       = $self->wheel_to_message_map->{$wheel_id};
		my $info     = $self->file_wheels->{$id};
		my $body     = $info->{accumulator};
		my $callback = $info->{callback};

		my $fn = $self->_get_filename($id);
		$self->log('debug', "Finished reading $fn");

		# clear our state
		delete $self->wheel_to_message_map->{$wheel_id};
		delete $self->file_wheels->{$id};

		# NOTE:  I have never seen this happen, but it seems theoretically 
		# possible.  Considering the former problem with leaking FD's, I'd 
		# rather keep this here just in case.
		$self->_unlink_file($id) if ($info->{delete_me});

		# send the message out!
		@_ = ($body);
		goto $callback;
	}
	else
	{
		$self->log( 'error', "$op: Error $errnum $errstr" );
	}
}

sub _write_flushed_event
{
	my ($self, $kernel, $wheel_id) = @_[ OBJECT, KERNEL, ARG0 ];

	# remove from the first map
	my $id = delete $self->wheel_to_message_map->{$wheel_id};

	$self->log( 'debug', "Finished writing message $id to disk" );

	# remove from the second map
	my $info = delete $self->file_wheels->{$id};

	# Write isn't pending anymore. :)
	delete $self->pending_writes->{$id};

	# If we were actively writing the file when the message to delete
	# came, we cannot actually delete it until the FD gets flushed, or the FD
	# will live until the program dies.
	$self->_unlink_file($id) if ($info->{delete_me});
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage::FileSystem -- A storage engine that keeps message bodies on the filesystem

=head1 SYNOPSIS

  use POE;
  use POE::Component::MessageQueue;
  use POE::Component::MessageQueue::Storage::FileSystem;
  use POE::Component::MessageQueue::Storage::DBI;
  use strict;

  # For mysql:
  my $DB_DSN      = 'DBI:mysql:database=perl_mq';
  my $DB_USERNAME = 'perl_mq';
  my $DB_PASSWORD = 'perl_mq';

  POE::Component::MessageQueue->new({
    storage => POE::Component::MessageQueue::Storage::FileSystem->new({
      info_storage => POE::Component::MessageQueue::Storage::DBI->new({
        dsn      => $DB_DSN,
        username => $DB_USERNAME,
        password => $DB_PASSWORD,
      }),
      data_dir => $DATA_DIR,
    })
  });

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

A storage engine that wraps around another storage engine in order to store
the message bodies on the file system.  The other message properties are
stored with the wrapped storage engine.

While I would argue that using this module is less efficient than using
L<POE::Component::MessageQueue::Storage::Complex>, using it directly would
make sense if persistance was your primary concern.  All messages stored via
this backend will be persistent regardless of whether they have the persistent
header set to true or not.  Every message is stored, even if it is handled
right away and will be removed immediately after having been stored.

=head1 CONSTRUCTOR PARAMETERS

=over 2

=item info_storage => L<POE::Component::MessageQueue::Storage>

The storage engine used to store message properties.

=item data_dir => SCALAR

The directory to store the files containing the message body's.

=back

=head1 SUPPORTED STOMP HEADERS

Be sure to check also the storage engine you are wrapping!

=over 4

=item B<persistent>

I<Ignored>.  All message bodies are always persisted.

=item B<expire-after>

I<Ignored>.  All message bodies are kept until handled.

=item B<deliver-after>

I<Fully Supported>.

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage>

I<Other storage engines:>

L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

=cut

