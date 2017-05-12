package POEx::ZMQ::Types;
$POEx::ZMQ::Types::VERSION = '0.005007';
use strict; use warnings FATAL => 'all';

use Type::Library   -base;
use Type::Utils     -all;
use Types::Standard -types;

use Module::Runtime ();

use POEx::ZMQ::Constants ();

declare ZMQContext =>
  as InstanceOf['POEx::ZMQ::FFI::Context'];

  # FIXME besides being lame, not very future-proof:
declare ZMQEndpoint =>
  as StrMatch[ qr{^(?:tcp|ipc|inproc|e?pgm)://\S+} ];

declare ZMQSocketBackend =>
  as InstanceOf['POEx::ZMQ::FFI::Socket'];

declare ZMQSocket =>
  as InstanceOf['POEx::ZMQ::Socket'],
  constraint_generator => sub {
    my $want_ztype = shift;
    if (my $sub = POEx::ZMQ::Constants->can($want_ztype)) {
      $want_ztype = $sub->()
    }
    sub { $_->type == $want_ztype }
  };

declare ZMQSocketType => as Int;
coerce  ZMQSocketType => 
  from Str() => via { 
    POEx::ZMQ::Constants->can($_) ? POEx::ZMQ::Constants->$_ : undef
  };

1;

=pod

=head1 NAME

POEx::ZMQ::Types - Type::Tiny types for use with POEx::ZMQ

=head1 SYNOPSIS

  use POEx::ZMQ;
  use POEx::ZMQ::Types -types;
  use Moo;

  has zmq_ctx => (
    is      => 'ro',
    isa     => ZMQContext,
    builder => sub { POEx::ZMQ->context },
  );

  has zmq_pub => (
    lazy    => 1,
    is      => 'ro',
    isa     => ZMQSocket[ZMQ_PUB],
    builder => sub {
      my ($self) = @_;
      POEx::ZMQ->socket(context => $self->zmq_ctx, type => ZMQ_PUB)
    },
  );

=head1 DESCRIPTION

L<Type::Tiny>-based types for L<POEx::ZMQ>.

=head2 ZMQContext

A L<POEx::ZMQ::FFI::Context> object.

=head2 ZMQEndpoint

A string that looks like a properly-formed ZeroMQ endpoint using a known
transport.

=head2 ZMQSocket

A L<POEx::ZMQ::Socket> object.

=head2 ZMQSocket[`a]

A L</ZMQSocket> can be parameterized with a given L</ZMQSocketType>.

=head2 ZMQSocketBackend

A L<POEx::ZMQ::FFI::Socket> object.

=head2 ZMQSocketType

A ZMQ socket type constant, such as those exported by L<POEx::ZMQ::Constants>.

Can be coerced from a string.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
