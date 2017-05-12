package Sendmail::Queue;
use strict;
use warnings;
use Carp;
use 5.8.0;

our $VERSION = '0.800';

use Sendmail::Queue::Qf;
use Sendmail::Queue::Df;
use File::Spec;
use IO::Handle;
use Fcntl qw( :flock );
use File::Temp qw(tempfile);
my $fcntl_struct = 's H60';
my $fcntl_structlockp = pack($fcntl_struct, Fcntl::F_WRLCK,
        "000000000000000000000000000000000000000000000000000000000000");
my $fcntl_structunlockp = pack($fcntl_struct, Fcntl::F_UNLCK,
        "000000000000000000000000000000000000000000000000000000000000");

use Sendmail::Queue::Base;
our @ISA = qw( Sendmail::Queue::Base );
__PACKAGE__->make_accessors(qw(
	queue_directory
	qf_directory
	df_directory
));

=head1 NAME

Sendmail::Queue - Manipulate Sendmail queues directly

=head1 SYNOPSIS

    use Sendmail::Queue;

    # The high-level interface:
    #
    # Create a new queue object.  Throws exception on error.
    my $q = Sendmail::Queue->new({
        queue_directory => '/var/spool/mqueue'
    });

    # Queue one copy of a message (one qf, one df)
    my $id = $q->queue_message({
	sender     => 'user@example.com',
	recipients => [
		'first@example.net',
		'second@example.org',
	],
	data       => $string_or_object,
    });

    # Queue multiple copies of a message using multiple envelopes, but
    # the same body.  Results contain the envelope name as key,
    # and the queue ID as the value.
    my %results = $q->queue_multiple({
	sender         => 'user@example.com',
	envelopes => {
		'envelope one' => {
			sender     => 'differentuser@example.com',
			recipients => [
				'first@example.net',
				'second@example.org',
			],
		},
		'envelope two' => {
			recipients => [
				'third@example.net',
				'fourth@example.org',
			],
		}
	},
	data           => $string_or_object,
    });

    # The low-level interface:

    # Create a new qf file object
    my $qf = Sendmail::Queue::Qf->new();

    # Generate a Sendmail 8.12-compatible queue ID
    $qf->create_and_lock();

    my $df = Sendmail::Queue::Df->new();

    # Need to give it the same queue ID as your $qf
    $df->set_queue_id( $qf->get_queue_id );
    $df->set_data( $some_body );

    # Or....
    $df->set_data_from( $some_fh );

    # Or, if you already have a file...
    my $second_df = Sendmail::Queue::Df->new();
    $second_df->set_queue_id( $qf->get_queue_id );
    $second_df->hardlink_to( $df ); # Need better name

    $qf->set_sender('me@example.com');
    $qf->add_recipient('you@example.org');

    $q->enqueue( $qf, $df );

=head1 DESCRIPTION

Sendmail::Queue provides a mechanism for directly manipulating Sendmail queue files.

=head1 METHODS

=head2 new ( \%args )

Create a new Sendmail::Queue object.

Required arguments are:

=over 4

=item queue_directory

The queue directory to use.  Should (usually) be the same as your
Sendmail QueueDirectory variable for the client submission queue.

=back

=cut

sub new
{
	my ($class, $args) = @_;

	$args ||= {};

	if(!exists $args->{queue_directory}) {
		die q{queue_directory argument must be provided};
	}

	my $self = { queue_directory => $args->{queue_directory}, };

	$self->{lock_both} = 0;

	bless $self, $class;

	if(!-d $self->{queue_directory}) {
		die q{ Queue directory doesn't exist};
	}

	if(-d File::Spec->catfile($self->{queue_directory}, 'qf')) {
		$self->set_qf_directory(File::Spec->catfile($self->{queue_directory}, 'qf'));
	} else {
		$self->set_qf_directory(File::Spec->catfile($self->{queue_directory}));
	}

	if(-d File::Spec->catfile($self->{queue_directory}, 'df')) {
		$self->set_df_directory(File::Spec->catfile($self->{queue_directory}, 'df'));
	} else {
		$self->set_df_directory(File::Spec->catfile($self->{queue_directory}));
	}

	# Check if both fcntl-style and flock-style locking is available
	my ($fh, $filename) = tempfile();
	if ($fh) {
		my $flock_status = flock($fh, LOCK_EX | LOCK_NB);
		my $fcntl_status = fcntl($fh, Fcntl::F_SETLK, $fcntl_structlockp);
		if ($flock_status && $fcntl_status) {
			$self->{lock_both} = 1;
		}
		$fh->close();
	}
	unlink($filename) if $filename;
	return $self;
}

=head2 queue_message ( $args )

High-level interface for queueing a message.  Creates qf and df files
in the object's queue directory using the arguments provided.

Returns the queue ID for the queued message.

Required arguments:

=over 4

=item sender

Envelope sender for message.

=item recipients

Array ref containing one or more recipients for this message.

=item data

Scalar containing message headers and body, in RFC-2822 format (ASCII
text, headers separated from body by \n\n).

Data should use local line-ending conventions (as used by Sendmail) and
not the \r\n used on the wire for SMTP.

=back

Optional arguments may be specified as well.  These will be handed off
directly to the underlying Sendmail::Queue::Qf object:

=over 4

=item product_name

Name to use for this product in the generated Recieved: header.  May be
set to blank or undef to disable.  Defaults to 'Sendmail::Queue'.

=item helo

The HELO or EHLO name provided by the host that sent us this message,
or undef if none.  Defaults to undef.

=item relay_address

The IP address of the host that sent us this message, or undef if none.
Defaults to undef.

=item relay_hostname

The name of the host that sent us this message, or undef if none.
Defaults to undef.

=item local_hostname

The name of the host that received this message.  Defaults to 'localhost'

=item protocol

Protocol over which this message was received.  Valid values are blank,
SMTP, and ESMTP.  Default is blank.

=item timestamp

A UNIX seconds-since-epoch timestamp.  If omitted, defaults to current time.

=item macros

A hash reference containing Sendmail macros that should be set in the resulting
queue file.

The names of macros should be the bare name, as the module will add the leading
$ and any surrounding {} necessary for multi-character macro names.

If omitted, the '$r' macro will be set to the 'protocol' value.  Other macros will
not be set by default.

=back

On error, this method may die() with a number of different runtime errors.

=cut

# FUTURE: use an exception class?

sub queue_message
{
	my ($self, $args) = @_;

	foreach my $argname qw( sender recipients data ) {
		die qq{$argname argument must be specified} unless exists $args->{$argname}

	}

	if( ref $args->{data} ) {
		die q{data as an object not yet supported};
	}

	$args->{envelopes} = {
		single_envelope => {
			recipients => delete $args->{recipients}
		}
	};

	my $result = $self->queue_multiple( $args );

	return $result->{single_envelope};
}

=head2 enqueue ( $qf, $df )

Enqueue a message, given a L<Sendmail::Queue::Qf> object and a
L<Sendmail::Queue::Df> object.

This method is mostly for internal use.  You should probably use
C<queue_message()> or C<queue_multiple()> instead.

Returns true if queuing was successful.  Otherwise, cleans up any qf
and df data that may have been written to disk, and rethrows any
exception that may have occurred.

=cut

=for internal doc

Here are the file ops (from inotify) on a /usr/sbin/sendmail enqueuing:

/var/spool/mqueue-client/ CREATE dfo2JEQb7J002161
/var/spool/mqueue-client/ OPEN dfo2JEQb7J002161
/var/spool/mqueue-client/ MODIFY dfo2JEQb7J002161
/var/spool/mqueue-client/ CLOSE_WRITE,CLOSE dfo2JEQb7J002161
/var/spool/mqueue-client/ OPEN dfo2JEQb7J002161
/var/spool/mqueue-client/ CREATE qfo2JEQb7J002161
/var/spool/mqueue-client/ OPEN qfo2JEQb7J002161
/var/spool/mqueue-client/ MODIFY qfo2JEQb7J002161
/var/spool/mqueue-client/ CREATE tfo2JEQb7J002161
/var/spool/mqueue-client/ OPEN tfo2JEQb7J002161
/var/spool/mqueue-client/ MODIFY tfo2JEQb7J002161
/var/spool/mqueue-client/ MOVED_FROM tfo2JEQb7J002161
/var/spool/mqueue-client/ MOVED_TO qfo2JEQb7J002161
/var/spool/mqueue-client/ OPEN,ISDIR 
/var/spool/mqueue-client/ CLOSE_NOWRITE,CLOSE,ISDIR 
/var/spool/mqueue-client/ CLOSE_WRITE,CLOSE qfo2JEQb7J002161
/var/spool/mqueue-client/ CLOSE_NOWRITE,CLOSE dfo2JEQb7J002161


=cut

sub enqueue
{
	my ($self, $qf, $df) = @_;

	eval {
		$df->write();
		$qf->write();
		$qf->sync();
		$qf->close();
	};
	if( $@ ) { ## no critic
		$df->unlink();
		$qf->unlink();

		# Rethrow the exception after cleanup
		die $@;
	}

	return 1;
}


=head2 queue_multiple ( $args )

Queue multiple copies of a message using multiple envelopes, but the
same body.

Returns a results hash containing the recipient set name as key, and the
queue ID as the value.


    my %results = $q->queue_multiple({
	envelopes => {
		'envelope one' => {
			sender     => 'user@example.com',
			recipients => [
				'first@example.net',
				'second@example.org',
			],
		}
		'envelope two' => {
			sender     => 'user@example.com',
			recipients => [
				'third@example.net',
				'fourth@example.org',
			],
		}
	},
	data           => $string_or_object,
    });

In the event that we cannot create a queue file for ANY of the envelopes, we
die() with an appropriate error after unlinking all created queue files --
either all succeed, or none succeed.

=cut

sub queue_multiple
{
	my ($self, $args) = @_;

	foreach my $argname qw( envelopes data ) {
		die qq{$argname argument must be specified} unless exists $args->{$argname}
	}

	if( ref $args->{data} ) {
		die q{data as an object not yet supported};
	}

	my ($headers, $data) = split(/\n\n/, $args->{data}, 2);

	my $qf = Sendmail::Queue::Qf->new({
		queue_directory => $self->get_qf_directory(),
	});

	# m// match is faster than tr/// for any case where there's an 8-bit
	# character before the end of the file, and is not significantly
	# slower in the case of no 8-bit characters.
	if( $data =~ m/[\200-\377]/o ) {
		# EF_HAS8BIT flag bit gets set if we have 8 bit characters in body.
		$qf->set_data_is_8bit(1);
	}

	# Allow passing of optional info down to Qf object
	foreach my $optarg qw( product_name helo relay_address relay_hostname local_hostname protocol timestamp macros ) {
		if( exists $args->{$optarg} ) {
			my $method = 'set_' . $optarg;
			$qf->$method($args->{$optarg} );
		}
	}

	# Prepare a generic queue file
	$qf->set_headers( $headers );

	my $first_df;
	my @queued_qfs = ();

	my %results;

	# Now, loop over all of the rest
	# FUTURE: validate data in the envelopes sections?
	eval {
		while( my($env_name, $env_data) = each %{ $args->{envelopes} } ) {
			my $cur_qf = $qf->clone();

			my $sender = exists $env_data->{sender}
					? $env_data->{sender}
					: exists $args->{sender}
						? $args->{sender}
						: die q{no 'sender' available};

			$cur_qf->set_sender( $sender );
			$cur_qf->add_recipient( @{ $env_data->{recipients} } );
			$cur_qf->create_and_lock($self->{lock_both});

			# As soon as it's created, put it on the list so it can
			# be cleaned up later if necessary.
			push @queued_qfs, $cur_qf;

			$cur_qf->synthesize_received_header();
			$cur_qf->write();
			$cur_qf->sync();

			my $cur_df = Sendmail::Queue::Df->new({
				queue_directory => $self->get_df_directory(),
				queue_id        => $cur_qf->get_queue_id(),
			});
			if( ! $first_df ) {
				# If this is the first one, create and write
				# the df file
				$first_df = $cur_df;
				$first_df->set_data( $data );
				$first_df->write();
			} else {
				# Otherwise, link to the first df
				eval { $cur_df->hardlink_to( $first_df->get_data_filename() ); };
				if ($@) {
					if ($@ =~ /Path .* does not exist/) {
						# This should NEVER happen...
						# but it was observed to happen!
						# Sorry to spew to STDERR, but there's no
						# feasible way to log this
						print STDERR 'Sendmail::Queue warning: ' . $first_df->get_data_filename() . ' has disappeared!  Writing new file as ' . $cur_df->get_data_filename() . "\n";
						$first_df = $cur_df;
						$first_df->set_data($data);
						$first_df->write();
					} else {
						die($@);
					}
				}
			}

			$results{ $env_name } = $cur_qf->get_queue_id;
		}

		$self->sync();

		# Close the queue files to release the locks
		$_->close() for (@queued_qfs);
	};
	if( $@ ) {
		# Something bad happened... wrap it all up and re-throw
		for my $qf (@queued_qfs) {
			my $df = Sendmail::Queue::Df->new({
				queue_directory => $self->get_df_directory(),
				queue_id        => $qf->get_queue_id(),
			});
			$df->unlink;
			$qf->unlink;
		}
		die $@;
	}

	return \%results;
}

=head2 sync ( )

Ensure that the queue directories have been synced.

=cut

sub sync
{
	my ($self) = @_;

	# Evil hack.  Why?  Well:
	#   - you can't fsync() a filehandle directly, you must use
	#     IO::Handle->sync
	# so, we have to sysopen to a filehandle glob, and then fdopen
	# the fileno we get from that glob.
	# FUTURE: File::Sync::fsync() can sync directories directly, but isn't core perl.
	# TODO: this needs testing on solaris and bsd
	my $directory = $self->get_df_directory();

	sysopen(DIR_FH, $directory, Fcntl::O_RDONLY) or die qq{Couldn't sysopen $directory: $!};

	my $handle = IO::Handle->new();
	$handle->fdopen(fileno(DIR_FH), 'w') or die qq{Couldn't fdopen the directory handle: $!};
	$handle->sync or die qq{Couldn't sync: $!};
	$handle->close;

	close(DIR_FH);

	return 1;
}

1;
__END__


=head1 DEPENDENCIES

=head2 Core Perl Modules

L<Carp>, L<File::Spec>, L<IO::Handle>, L<Fcntl>

=head2 Other Modules

L<Sendmail::Queue::Qf>, L<Sendmail::Queue::Df>

=head1 INCOMPATIBILITIES

There are no known incompatibilities with this module.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.  However, it messes with
undocumented bits of Sendmail.  YMMV.

Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Dave O'Neill, C<< <support at roaringpenguin.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
