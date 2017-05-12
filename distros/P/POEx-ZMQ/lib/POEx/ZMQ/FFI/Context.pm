package POEx::ZMQ::FFI::Context;
$POEx::ZMQ::FFI::Context::VERSION = '0.005007';
use Carp;
use strictures 2;

use List::Objects::WithUtils;

use FFI::Raw;

use POEx::ZMQ::Constants
  'ZMQ_IO_THREADS',
  'ZMQ_MAX_SOCKETS';

use POEx::ZMQ::FFI;
use POEx::ZMQ::FFI::Cached;
use POEx::ZMQ::FFI::Callable;
use POEx::ZMQ::FFI::Socket;

use Types::Standard -types;


use Moo; use MooX::late;


has soname => (
  is        => 'ro',
  isa       => Str,
  builder   => sub { POEx::ZMQ::FFI->find_soname },
);

has threads => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  predicate => 1,
  builder   => sub { 1 },
);

has max_sockets => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  predicate => 1,
  builder   => sub { 1023 },
);


has _ffi => ( 
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::ZMQ::FFI::Callable'],
  builder   => '_build_ffi',
);

sub _build_ffi {
  my ($self) = @_;
  my $soname = $self->soname;
  
  my $ffi = POEx::ZMQ::FFI::Cached->get(Context => $soname);
  return $ffi if defined $ffi;

  POEx::ZMQ::FFI::Cached->set(
    Context => $soname => POEx::ZMQ::FFI::Callable->new(
      zmq_ctx_new => FFI::Raw->new(
        $soname, zmq_ctx_new => 
          FFI::Raw::ptr,   # <- ctx ptr
      ),

      zmq_ctx_set => FFI::Raw->new(
        $soname, zmq_ctx_set =>
          FFI::Raw::int,   # <- rc
          FFI::Raw::ptr,   # -> ctx ptr
          FFI::Raw::int,   # -> opt (constant)
          FFI::Raw::int,   # -> opt value
      ),

      zmq_ctx_get => FFI::Raw->new(
        $soname, zmq_ctx_get =>
          FFI::Raw::int,  # <- opt value
          FFI::Raw::ptr,  # -> ctx ptr
          FFI::Raw::int,  # -> opt (constant)
      ),

      zmq_ctx_destroy => FFI::Raw->new(
        $soname, zmq_ctx_destroy =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> ctx ptr
      ),

      ( $self->get_zmq_version->major >= 4 ?
          (
            zmq_curve_keypair => FFI::Raw->new(
              $soname, zmq_curve_keypair =>
                FFI::Raw::int,  # <- rc
                FFI::Raw::ptr,  # -> pub key ptr
                FFI::Raw::ptr,  # -> priv key ptr
            )
          )
          : ()
      ),
    )
  )
}

has _ctx_ptr => (
  lazy      => 1,
  is        => 'ro',
  isa       => Defined,
  writer    => '_set_ctx_ptr',
  predicate => '_has_ctx_ptr',
  builder   => sub {
    my ($self) = @_;
    $self->_ffi->zmq_ctx_new // $self->throw_zmq_error('zmq_ctx_new');
  },
);
sub get_raw_context { shift->_ctx_ptr }


with 'POEx::ZMQ::FFI::Role::ErrorChecking';


=for Pod::Coverage BUILD DEMOLISH

=cut

sub BUILD {
  my ($self) = @_;
  $self->set_ctx_opt(ZMQ_IO_THREADS, $self->threads) if $self->has_threads;
  $self->set_ctx_opt(ZMQ_MAX_SOCKETS, $self->max_sockets)
    if $self->has_max_sockets;
}

sub DEMOLISH {
  my ($self, $gd) = @_;
  return if $gd;
  return unless $self->_has_ctx_ptr;
  $self->throw_if_error( zmq_ctx_destroy =>
    $self->_ffi->zmq_ctx_destroy( $self->_ctx_ptr )
  );
}


sub create_socket {
  my ($self, $type) = @_;
  POEx::ZMQ::FFI::Socket->new(
    context     => $self,
    type        => $type,
    soname      => $self->soname,
  )
}

sub get_zmq_version { POEx::ZMQ::FFI->get_version( $_[0]->soname ) }

sub get_ctx_opt {
  my ($self, $opt) = @_;
  my $val;
  $self->throw_if_error( zmq_ctx_get =>
    ( $val = $self->_ffi->zmq_ctx_get( $self->_ctx_ptr, $opt ) )
  );
  $val  
}

sub set_ctx_opt {
  my ($self, $opt, $val) = @_;
  $self->throw_if_error( zmq_ctx_set =>
    $self->_ffi->zmq_ctx_set( $self->_ctx_ptr, $opt, $val )
  );
}

sub generate_keypair {
  my ($self) = @_;

  carp __PACKAGE__."::generate_keypair is deprecated and will be removed!\n",
       "Use Crypt::ZCert instead.";

  unless ($self->_ffi->can('zmq_curve_keypair')) {
    confess "Cannot generate key pair; missing zmq_curve_keypair support"
  }

  my ($pub, $sec) = (
    FFI::Raw::memptr(41),
    FFI::Raw::memptr(41)
  );

  $self->throw_if_error( zmq_curve_keypair =>
    $self->_ffi->zmq_curve_keypair( $pub, $sec )
  );

  hash(
    public => POEx::ZMQ::FFI->zunpack('string', undef, $pub),
    secret => POEx::ZMQ::FFI->zunpack('string', undef, $sec)
  )->inflate
}

1;

=pod

=for Pod::Coverage has_(?:threads|max_sockets)

=for Pod::Coverage generate_keypair

=head1 NAME

POEx::ZMQ::FFI::Context - Backend ZeroMQ context objects for POEx::ZMQ

=head1 SYNOPSIS

  # Used internally by POEx::ZMQ; see below for useful methods

=head1 DESCRIPTION

An object representing a ZeroMQ context.

These are typically created via a higher-level mechanism (see L<POEx::ZMQ>)
and accessible from your L<POEx::ZMQ::Socket> instance:

  my $ctx = $my_sock->context;
  my $keypair = $ctx->generate_keypair;
  # ...

=head2 ATTRIBUTES

=head3 soname

The dynamic library name to use (see L<FFI::Raw>).

Defaults to calling L<POEx::ZMQ::FFI/"find_soname">.

=head3 threads

The size of the ZeroMQ IO thread pool.

Defaults to 1.

=head3 max_sockets

The maximum number of sockets allowed on this context.

Defaults to 1023 (the ZMQ4 default).

=head2 METHODS

=head3 create_socket

  my $sock = $ctx->create_socket($type);

Returns a new L<POEx::ZMQ::FFI::Socket> for the given type.

There is no destroy method; the ZeroMQ context is terminated when the object,
and any sock created on this context, falls out of scope.

=head3 get_ctx_opt

  my $val = $ctx->get_ctx_opt( $option );

Retrieve context options.

See L<zmq_ctx_get(3)>.

=head3 set_ctx_opt

  $ctx->set_ctx_opt( $option, $value );

Set context options.

See L<zmq_ctx_set(3)>.

=head3 get_raw_context

Returns the raw context pointer, suitable for use with direct L<FFI::Raw>
calls (used internally by L<POEx::ZMQ::FFI::Socket> objects).

=head3 get_zmq_version

  my $vstruct = $ctx->get_zmq_version;
  my $major   = $vstruct->major;
  # See POEx::ZMQ::FFI for complete method list

Returns the L<POEx::ZMQ::FFI/get_version> struct-like object for the current
L</soname>.

=head2 CONSUMES

L<POEx::ZMQ::FFI::Role::ErrorChecking>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Significant portions of this code are inspired by or derived from L<ZMQ::FFI>
by Dylan Calid (CPAN: CALID).

=cut
