package POEx::ZMQ::FFI::Error;
$POEx::ZMQ::FFI::Error::VERSION = '0.005007';
use strictures 2;


use Moo; use MooX::late;
extends 'Throwable::Error';


has function => (
  required  => 1,
  is        => 'ro',
);

has errno => (
  required  => 1,
  is        => 'ro',
);

sub errstr { $_[0]->message }


1;

=pod

=head1 NAME

POEx::ZMQ::FFI::Error

=head1 SYNOPSIS

  # Used internally by POEx::ZMQ

=head1 DESCRIPTION

Exception objects thrown when errors are produced by the ZeroMQ backend.

This class extends L<Throwable::Error>.

=head2 ATTRIBUTES

=head3 errno

The current L<zmq_errno(3)>.

=head3 errstr

Alias for L</message> (getter-only).

=head3 function

The libzmq function that produced the error.

=head3 message

The error string; typically the current L<zmq_strerror(3)>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
