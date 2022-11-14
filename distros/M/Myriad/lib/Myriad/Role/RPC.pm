package Myriad::Role::RPC;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Myriad::Role::RPC - microservice RPC abstraction

=head1 SYNOPSIS

 my $rpc = $myriad->rpc;

=head1 DESCRIPTION

=head1 Implementation

Note that this is defined as a rôle, so it does not provide
a concrete implementation - instead, see classes such as:

=over 4

=item * L<Myriad::RPC::Implementation::Redis>

=item * L<Myriad::RPC::Implementation::Memory>

=back

=cut

no indirect qw(fatal);
use Role::Tiny;

use Future::AsyncAwait;

use Myriad::RPC::Message;

=head1 METHODS

The following methods are required in any concrete classes which implement this rôle.

=head2 start

Activate RPC - begin listening for messages.

Expected to return a L<Future> which resolves once we think this instance is ready
and able to process requests.

=cut

requires 'start';

=head2 create_from_sink

Register a new RPC method and attach a L<Ryu::Sink> to be able to publish messages when they are received.

=cut

requires 'create_from_sink';

=head2 stop

Deäctivate RPC - stop listening for messages.

This is the counterpart to L</start>.

Expected to return a L<Future> which resolves once we are guaranteed not to pick up
any further new requests.

=cut

requires 'stop';

=head2 reply_success

Reply back to the sender of the message with success payload.
The method will take the raw response and take care of how we are going to encapsulate it.

=over 4

=item * message - The message we are processing.

=item * response - The success response.

=back

=cut

requires 'reply_success';

=head2 reply_error

Same concept of C<reply_success> but for errors.

=over 4

=item * C<message> - the message we are processing

=item * C<error> - the L<Myriad::Exception> that happened while processing the message

=back

=cut

requires 'reply_error';

=head2 drop

This should be used to handle dead messages (messages that we couldn't even parse).

It doesn't matter how the implementation is going to deal with it (delete it/ move it to another queue ..etc) the RPC handler
should call this method when it's unable to parse a message and we can't reply to the client.

=over 4

=item * C<id> - message id

=back

=cut

requires 'drop';

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

