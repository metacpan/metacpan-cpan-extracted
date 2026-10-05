package FakeHTTP;

# What Net::Async::Authentik needs from Net::Async::HTTP, answered by the
# in-memory authentik of t/lib/FakeAuthentik.pm as already completed futures.
# No loop is needed.

use strict;
use warnings;
use Future;
use FakeAuthentik;

sub new {
  my ( $class, %arg ) = @_;
  return bless { fake => $arg{fake} || FakeAuthentik->new(%arg) }, $class;
}

sub fake { $_[0]{fake} }

sub do_request {
  my ( $self, %arg ) = @_;
  return Future->done( $self->{fake}->request( $arg{request} ) );
}

1;
