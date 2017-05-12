package POEx::ZMQ;
$POEx::ZMQ::VERSION = '0.005007';
use strictures 2;

use Scalar::Util 'blessed';

use Import::Into;

use POEx::ZMQ::FFI::Context;

use POEx::ZMQ::Constants ();
use POEx::ZMQ::Socket ();

sub ZCTX () { 0 }

use namespace::clean;

=for Pod::Coverage import ZCTX

=cut

sub import {
  my $pkg = caller;
  POEx::ZMQ::Constants->import::into($pkg, '-all');
}

sub new {
  my ($class, %param) = @_;
  bless [ $param{context} ], $class
}

sub context {
  my $self_or_class = shift;
  if (blessed $self_or_class) {
    return ( $self_or_class->[ZCTX] ||= POEx::ZMQ::FFI::Context->new(@_) )
  }
  POEx::ZMQ::FFI::Context->new(@_)
}

sub socket {
  my ($self_or_class, %param) = @_;
  POEx::ZMQ::Socket->new(
    context => (
      exists $param{context} ? delete $param{context} : $self_or_class->context
    ),
    %param
  )
}

1;


=pod

=head1 NAME

POEx::ZMQ - Asynchronous ZeroMQ sockets for POE

=head1 SYNOPSIS

  # An example ZMQ_ROUTER socket ->
  use POE;
  use POEx::ZMQ;

  POE::Session->create(
    inline_states => +{
      _start => sub {
        # Set up a ROUTER
        # Save our POEx::ZMQ for creating other sockets w/ shared context later:
        my $zmq = POEx::ZMQ->new;
        $_[HEAP]->{zeromq} = $zmq;

        $_[HEAP]->{rtr} = $zmq->socket( type => ZMQ_ROUTER );

        $_[HEAP]->{rtr}->start;

        $_[HEAP]->{rtr}->bind( 'tcp://127.0.0.1:1234' );
      },

      zmq_recv_multipart => sub {
        # ROUTER received a message; sender identity is prefixed,
        # parts are available as a List::Objects::WithUtils::Array ->
        my $parts = $_[ARG0];

        # Handle the usual ZeroMQ message framing scheme by capturing
        # prefixed identities including empty message delimiter, followed
        # by our message body:
        my $envelope = $parts->items_before(sub { $_ eq '' });
        my $content  = $parts->items_after(sub { $_ eq '' });

        # $_[SENDER] was the ROUTER socket, send a response back to origin:
        $_[KERNEL]->post( $_[SENDER], send_multipart =>
          [ $envelope, '', 'foo' ]
        );
      },
    },
  );

  POE::Kernel->run;

=head1 DESCRIPTION

A L<POE> component providing non-blocking L<ZeroMQ|http://www.zeromq.org>
(versions 3.x & 4.x) integration.

See L<POEx::ZMQ::Socket> for details on using these sockets and the
L<zmq_socket(3)> man page regarding behavior of each socket type.

See the L<zguide|http://zguide.zeromq.org> for more on using ZeroMQ in
general.

Each ZeroMQ socket is an event emitter powered by L<MooX::Role::POE::Emitter>;
the documentation for that distribution is likely to be helpful.

If you are not using L<POE>, try L<ZMQ::FFI> for an excellent loop-agnostic
ZeroMQ implementation.

=head2 import 

Importing this package brings in the full set of L<POEx::ZMQ::Constants>, and
ensures L<POEx::ZMQ::Socket> is loaded.

=head3 new

  my $zmq = POEx::ZMQ->new;
  # POEx::ZMQ::FFI::Context obj is automatically shared:
  my $frontend = $zmq->socket(type => ZMQ_ROUTER);
  my $backend  = $zmq->socket(type => ZMQ_ROUTER);

This class can be instanced, in which case it will hang on to the first
L</context> created (possibly implicitly via a call to L</socket>) and use
that L<POEx::ZMQ::FFI::Context> instance for all calls to L</socket>.

=head3 context

  my $ctx = POEx::ZMQ->context(max_sockets => 512);

If called as a class method, returns a new L<POEx::ZMQ::FFI::Context>.

  my $zmq = POEx::ZMQ->new;
  my $ctx = $zmq->context;

If called as an object method, returns the context object belonging to the
instance. If none currently exists, a new L<POEx::ZMQ::FFI::Context> is
created (and preserved for use during socket creation; see L</socket>).

If creating a new context object, C<@_> is passed through to the
L<POEx::ZMQ::FFI::Context> constructor.

The context object should typically be shared between sockets belonging to the
same process. However, multiple contexts may exist within the same
application (and they may have their own respective library C<soname>).
A forked child process must create a new L<POEx::ZMQ::FFI::Context> with its
own set of sockets.

The context object provides access to other useful ZeroMQ functionality, such
as library version number retrieval and CURVE key pair generation. See
L<POEx::ZMQ::FFI::Context> for details.

=head3 socket

  my $sock = POEx::ZMQ->socket(context => $ctx, type => ZMQ_ROUTER);

If called as a class method, returns a new L<POEx::ZMQ::Socket> using either
a provided C<context> or, if missing from arguments, a freshly-created
L<POEx::ZMQ::FFI::Context>.

  my $sock = $zmq->socket(type => ZMQ_ROUTER);

If called as an object method, returns a new L<POEx::ZMQ::Socket> that uses
the L<POEx::ZMQ::FFI::Context> object belonging to the instance; see
L</new> & L</context>.

C<@_> is passed through to the L<POEx::ZMQ::Socket> constructor.

=head1 KNOWN BUGS

Dumps core upon process exit on FreeBSD before C<10.x>. Do not know why and
have not debugged, but patches welcome? ;-)

=head1 SEE ALSO

L<POEx::ZMQ::Socket>

L<POEx::ZMQ::Constants>

L<POEx::ZMQ::Types>

L<POEx::ZMQ::FFI::Socket>

L<POEx::ZMQ::FFI::Context>

L<POEx::ZMQ::FFI>

L<Text::ZPL> for ZeroMQ Property Language support.

L<Crypt::ZCert> for ZeroMQ4+ CURVE certificate management & key pair
generation.

L<Convert::Z85> for encoding/decoding CURVE keys (see L<zmq_curve(7)> on
libzmq4+).

L<ZMQ::FFI> for a lower-level, non-POE interface to ZeroMQ sockets.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Significant portions of the L<POEx::ZMQ::FFI> backend are inspired by or
derived from L<ZMQ::FFI> (version 0.14) by Dylan Cali (CPAN: CALID).

Licensed under the same terms as Perl.

=cut
