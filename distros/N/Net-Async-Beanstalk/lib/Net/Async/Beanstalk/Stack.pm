package Net::Async::Beanstalk::Stack;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Net::Async::Beanstalk::Stack - A FIFO stack of queued commands

=head1 DOCUMENTED ELSEWHERE

This module's external API is undocumented.

=cut

use Moo::Role;
use strictures 2;

use Carp;
use MooX::HandlesVia;
use namespace::clean;

# TODO: Document internal API

=head1 ATTRIBUTES

=over

=item _command_stack

=for comment Documented last because this attribue isn't particularly
interesting to users of this module.

An internal FIFO stack of commands which are waiting to be sent or
responded to.

Accessors:

=over

=item count_commands

How many commands are in the stack, including the one which the server
is currently processing.

=item current_command

Returns the command the server is currently processing, or has just
sent a response to, without removing it from the stack.

=item is_busy

A boolean indicating whether the client is busy, ie. has a command
currently being processed or has commands waiting to be sent. Actually
implemented by the same method as L</count_commands>.

=item _pending_commands

Returns the commands which have not yet completed, including the one
which the server is currently processing.

=item _push_command

Push a new command onto the stack.

=item _shift_command

Remove and return the first command from the stack, which the server
is either processing or has returned a response to.

=back

=cut

has _command_stack => (
  is          => 'ro',
  init_arg    => undef,
  default     => sub { [] },
  handles_via => 'Array',
  handles     => {
    count_commands    => 'count',
    is_busy           => 'count',
    _pending_commands => 'all',
    _push_command     => 'push',
    _shift_command    => 'shift',
  },
);

sub current_command { $_[0]->_command_stack->[0] || croak "No active command" }

=back

=cut

1;
