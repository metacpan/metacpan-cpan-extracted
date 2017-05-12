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

package POE::Component::MessageQueue::Storage;
use Moose::Role;
use POE::Component::MessageQueue::Logger;

requires qw(
	get            get_all 
	get_oldest     claim_and_retrieve
	claim          store
	disown_all     disown_destination
	empty          remove     
	storage_shutdown
);

# Given a method name, makes its first argument OPTIONALLY be an aref.  If it
# is not an aref, it normalizes it into one.  If mangle_callback is true, it
# also unpacks it in the callback.
sub _areffify
{
	my ($method, $mangle_callback) = @_;

	around($method => sub {
		my @args = @_;
		my $original = shift(@args);
		my $arg = $args[1];
		unless (ref $arg eq 'ARRAY')
		{
			$args[1] = [$arg];
			if ($mangle_callback)
			{
				my $cb = $args[-1];
				$args[-1] = sub {
					my @response = @_;
					my $arr = $response[0];
					$response[0] = (@$arr > 0) ? $arr->[0] : undef;
					@_ = @response;
					goto $cb;
				}
			};
		}	
		@_ = @args;
		goto $original;
	});
}

_areffify($_, 1) foreach qw(get);
_areffify($_, 0) foreach qw(claim remove);

has 'names' => (
	is      => 'rw',
	isa     => 'ArrayRef',
	writer  => 'set_names',
	default => sub { [] },
);

has 'namestr' => (
	is      => 'rw',
	isa     => 'Str',
	default => q{},
);

has 'children' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} },
);

has 'logger' => (
	is      => 'rw',
	writer  => 'set_logger',
	default => sub { POE::Component::MessageQueue::Logger->new() },
);

sub add_names
{
	my ($self, @names) = @_;
	my @prev_names = @{$self->names};
	push(@prev_names, @names);
	$self->set_names(\@prev_names);
}

after 'set_names' => sub {
	my ($self, $names) = @_;
	while (my ($name, $store) = each %{$self->children})
	{
		$store->set_names([@$names, $name]);
	}
	$self->namestr(join(': ', @$names));
};

sub log
{
	my ($self, $type, $msg, @rest) = @_;
	my $namestr = $self->namestr;
	return $self->logger->log($type, "STORE: $namestr: $msg", @rest);
}

1;

__END__

=pod

=head1 NAME

POE::Component::MessageQueue::Storage -- Parent of provided storage engines

=head1 DESCRIPTION

The role implemented by all storage engines.  It provides a few bits of global
functionality, but mostly exists to define the interface for storage engines.

=head1 CONCEPTS

=over 2

=item optional arefs

Some functions take an "optional aref" as an argument.  What this means is
that you can pass either a plain-old-scalar argument (such as a message id) or
an arrayref of such objects.  If you pass the former, your callback (if any)
will receive a single value.  If the latter, it will receive an arrayref.
Note that the normalization is done by this role - storage engines need only
implement the version that takes an aref, and send arefs to the callbacks.

=item callbacks

Every storage method has a callback as its last argument.  Callbacks are Plain
Old Subs. If the method doesn't have some kind of return value, the callback is 
optional and has no arguments.  It's simply called so you you know the method
is done.   If the method does have some kind of return value, the 
callback is not optional and the argument will be said value.  Return values
of storage functions are not significant and should never be used.  Unless
otherwise specified, assume the functions below have plain success callbacks.

=back

=head1 INTERFACE

=over 2

=item set_logger I<SCALAR>

Takes an object of type L<POE::Component::MessageQueue::Logger> that should be 
used for logging.  This isn't a storage method and does not have any callback
associated with it.

=item store I<Message>

Takes one or more objects of type L<POE::Component::MessageQueue::Message> 
that should be stored.

=item get I<optional-aref>

Passes the message(s) specified by the passed id(s) to the callback.

=item get_all

=item get_oldest

Self-explanatory.

=item remove I<optional-aref>

Removes the message(s) specified by the passed id(s).

=item empty

Deletes all messages from the storage engine.

=item claim I<optional-aref>, I<client-id>

Naively claims the specified messages for the specified client, even if they
are already claimed.  This is intended to be called by stores that wrap other
stores to maintain synchronicity between multiple message copies - non-store
clients usually want claim_and_retrieve.

=item claim_and_retrieve I<destination>, I<client-id>

Claims the "next" message intended for I<destination> for I<client-id> and
passes it to the supplied callback.  Storage engines are free to define what 
"next" means, but the intended meaning is "oldest unclaimed message for this 
destination".

=item disown_all I<client-id>

Disowns all messages owned by the client.

=item disown_destination I<destination>, I<client-id>

Disowns the message owned by the specified client on the specified
destination.  (This should only be one message).

=item storage_shutdown

Starts shutting down the storage engine.  The storage engine will
attempt to do any cleanup (persisting of messages, etc) before calling the
callback.

=back

=head1 SEE ALSO

L<POE::Component::MessageQueue>,
L<POE::Component::MessageQueue::Storage::BigMemory>,
L<POE::Component::MessageQueue::Storage::Memory>,
L<POE::Component::MessageQueue::Storage::DBI>,
L<POE::Component::MessageQueue::Storage::FileSystem>,
L<POE::Component::MessageQueue::Storage::Generic>,
L<POE::Component::MessageQueue::Storage::Generic::DBI>,
L<POE::Component::MessageQueue::Storage::Double>,
L<POE::Component::MessageQueue::Storage::Throttled>,
L<POE::Component::MessageQueue::Storage::Complex>,
L<POE::Component::MessageQueue::Storage::Default>

=cut
