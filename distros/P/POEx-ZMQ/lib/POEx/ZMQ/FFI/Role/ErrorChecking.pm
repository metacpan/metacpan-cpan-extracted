package POEx::ZMQ::FFI::Role::ErrorChecking;
$POEx::ZMQ::FFI::Role::ErrorChecking::VERSION = '0.005007';
use v5.10;
use Carp 'cluck', 'confess';
use strictures 2;

use POEx::ZMQ::FFI::Cached;
use POEx::ZMQ::FFI::Callable;
use POEx::ZMQ::FFI::Error;

use Types::Standard -types;

use FFI::Raw;

use Moo::Role;
requires 'soname';

has err_handler => (
  lazy    => 1,
  is      => 'ro',
  isa     => InstanceOf['POEx::ZMQ::FFI::Callable'],
  builder => '_build_ffi',
);

sub _build_ffi {
  my ($self) = @_;
  my $soname = $self->soname;
  
  my $ffi = POEx::ZMQ::FFI::Cached->get(ErrHandler => $soname);
  return $ffi if defined $ffi;

  POEx::ZMQ::FFI::Cached->set(
    ErrHandler => $soname => POEx::ZMQ::FFI::Callable->new(
      zmq_errno => FFI::Raw->new(
        $soname, zmq_errno => FFI::Raw::int
      ),

      zmq_strerror => FFI::Raw->new(
        $soname, zmq_strerror =>
          FFI::Raw::str,  # <- errstr
          FFI::Raw::int,  # -> errno
      ),
    )
  )
}


sub errno  { $_[0]->err_handler->zmq_errno }
sub errstr { $_[0]->err_handler->zmq_strerror( $_[1] // $_[0]->errno ) }

sub _create_zmq_error {
  my $errno  = $_[0]->errno;
  POEx::ZMQ::FFI::Error->new(
    message  => $_[0]->errstr($errno),
    errno    => $errno,
    function => ($_[1] // confess "Missing function name"),
  ) 
}

sub throw_zmq_error {
  $_[0]->_create_zmq_error(@_[1 .. $#_])->throw
}

sub throw_if_error {
  confess "Expected function name and return code"
    unless defined $_[2];
  $_[0]->throw_zmq_error($_[1]) if $_[2] == -1;
  $_[0]
}

sub warn_if_error {
  confess "Expected function name and return code"
    unless defined $_[2];

  if ($_[2] == -1) {
    my $err = $_[0]->_create_zmq_error($_[1]);
    cluck $err . "\n";
    return
  }

  $_[0]
}

1;


=pod

=head1 NAME

POEx::ZMQ::FFI::Role::ErrorChecking

=head1 SYNOPSIS

  # Used internally by POEx::ZMQ

=head1 DESCRIPTION

A L<Moo::Role> consumed by classes comprising the L<POEx::ZMQ> FFI backend.

Errors produced/thrown by these methods are instances of L<POEx::ZMQ::FFI::Error>.

=head2 ATTRIBUTES

=head3 err_handler

The error handler is a L<POEx::ZMQ::FFI::Callable> instance providing direct
access to the L<zmq_errno(3)> and L<zmq_strerror(3)> functions.

=head2 METHODS

=head3 errno

Calls L<zmq_errno(3)> to get the errno value for the previous (failed) call.

Used to build a thrown L<POEx::ZMQ::FFI::Error>.

=head3 errstr

Calls L<zmq_strerror(3)> to get the error string for the current L</errno>.

An C<errno> can be supplied if one was previously retrieved:

  my $errstr = $self->errstr( $errno );

Used to build a thrown L<POEx::ZMQ::FFI::Error>.

=head3 throw_zmq_error

  $self->throw_zmq_error( $zmq_function );

Throws a L<POEx::ZMQ::FFI::Error>, unconditionally.

The ZMQ function name is purely informational; L</errno> and L</errstr> are
automatically retrieved for inclusion in the thrown exception object.

=head3 throw_if_error

  $self->throw_if_error( $zmq_function =>
    $call_zmq_ffi_func->(@args)
  );

Takes a ZMQ function name and a return code from a ZMQ FFI call; calls
L</throw_zmq_error> if the return code indicates the call failed.

=head3 warn_if_error

Like L</throw_if_error>, but warn via L<Carp/cluck> rather than throwing an
error object.

Returns the invocant if there was no error, else returns false.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
