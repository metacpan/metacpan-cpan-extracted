package FakeHTTP;

# What Net::Async::Keycloak needs from Net::Async::HTTP, answered by the
# in-memory Keycloak of t/lib/FakeKeycloak.pm (shared with WWW::Keycloak's
# tests) as already completed futures. No loop is needed.

use strict;
use warnings;
use Future;
use FakeKeycloak;

sub new {
  my ( $class, %arg ) = @_;
  return bless { fake => $arg{fake} || FakeKeycloak->new(%arg) }, $class;
}

sub fake { $_[0]{fake} }

sub do_request {
  my ( $self, %arg ) = @_;
  return Future->done( $self->{fake}->request( $arg{request} ) );
}

1;
