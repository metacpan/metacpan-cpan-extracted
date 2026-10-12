package Object::Remote::Connector::UNIX;

use IO::Socket::UNIX;
use Moo;

with 'Object::Remote::Role::Connector';

has socket_path => (is => 'ro', required => 1);

sub _open2_for {
  my ($self) = @_;
  my $path = $self->socket_path;
  my $sock = IO::Socket::UNIX->new($path)
    or die "Couldn't open socket ${path}: $!";
  ($sock, $sock, undef);
}

no warnings 'once';

push @Object::Remote::Connection::Guess, sub {
  for ($_[0]) {
    if (defined and !ref and /^(?:\.\/|\/)/) {
      my $socket = shift(@_);
      return __PACKAGE__->new(@_, socket_path => $socket);
    }
  }
  return;
};

1;

=head1 NAME

Object::Remote::Connector::UNIX - Connect to an Object::Remote server over a Unix socket

=head1 SYNOPSIS

  use Object::Remote;

  my $remote = Object::Remote->connect('/tmp/object-remote.sock');

=head1 DESCRIPTION

C<Object::Remote::Connector::UNIX> provides the client-side connector for
connecting to an L<Object::Remote::ConnectionServer> instance over a Unix
domain socket.

It is selected automatically when the connection target looks like a Unix
socket path, such as one beginning with C</> or C<./>.

=head1 METHODS

This class is an internal connector implementation and does not provide a
public API beyond what is consumed by L<Object::Remote>.

=head1 SEE ALSO

L<Object::Remote>, L<Object::Remote::ConnectionServer>, L<IO::Socket::UNIX>

=cut
