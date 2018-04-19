package MooX::Async::Console::TCPClient;

=head1 NAME

MooX::Async::Console::TCPClient - TCP client interaction for MooX::Async::Console

=head1 SYNOPSIS

See L<MooX::Async::Console>

=head1 DESCRIPTION

A L<IO::Async::Stream> subclass which waits for a complete line of
text and invokes L</on_line>.

=head1 BUGS

Certainly.

=cut

use Modern::Perl '2017';
use strictures 2;

use Moo;
use MooX::Async;
use namespace::clean;

extends MooXAsync('Stream');

with 'MooX::Role::Logger';

=head1 ATTRIBUTES

=over

=item id

A string composed from L</address> and L</port> which identifies this
client.

=cut

has id => is => lazy => init_arg => undef, builder =>
  sub { sprintf 'tcp:%s:%s', $_[0]->address, $_[0]->port };

=item address

The IP address this client connected from.

=cut

has address => is => lazy => init_arg => undef, builder =>
  sub { $_[0]->read_handle->peerhost }; # TODO: Force normalised ipv6

=item port

The TCP port this client connected from.

=cut

has port => is => lazy => init_arg => undef, builder =>
  sub { $_[0]->read_handle->peerport };

=back

=head1 METHODS

=over

=item flush

Flush the client's write buffer.

=cut

sub flush { $_[0]->write('')->get }

=item say

Write the arguments to the stream with C<\n> appended.

=cut

sub say { $_[0]->write($_[1] . "\n") }

=back

=head1 EVENTS

=over

=item on_close

Invoked when the client has closed the connection.

=item on_line

Invoked when the client has a complete line of text which is not just
whitespace.

=cut

event $_ for qw(on_close on_line);

=item on_error

Implemented by this module to close the connection and invoke
C<on_close> when there's an error.

=cut

sub on_error {
  local $_[0]->_logger->context->{client} = $_[0]->id;
  $_[0]->_logger->errorf('%s write error: %s', ref $_[0], [ @_[1..$#_] ]);
  $_[0]->close;
  $_[0]->invoke_event(on_close => 'error', @_[1..$#_]);
}

=item on_read

Implemented by this module to detect a complete line in the read
buffer and invoke C<on_line>.

=cut

sub on_read {
  my $self = shift;
  local $self->_logger->context->{client} = $self->id;
  my ($rbuf, $eof) = @_;
  while ($$rbuf =~ s/^(.*?)\r?\n//) {
    next unless length $1 or $1 =~ /^\s+$/;
    $self->invoke_event(on_line => $1);
  }
  return $eof ? 0 : 0+! length $$rbuf;
}

=item on_read_eof

Implemented by this module to invoke C<on_close> when the client
disconnects.

=cut

sub on_read_eof {
  local $_[0]->_logger->context->{client} = $_[0]->id;
  $_[0]->invoke_event(on_close => 'EOF');
}

1;

=back

=head1 SEE ALSO

L<MooX::Async::Console>

L<MooX::Async::Console::TCP>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut
