package OpenSearch::Parameters::Security::CreateUser;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str ArrayRef HashRef);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'username' => (
  is       => 'rw',
  isa      => Str,
  required => 1
);

has 'password' => (
  is       => 'rw',
  isa      => Str,
  required => 1
);

has 'opendistro_security_roles' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 0
);

has 'backend_roles' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 0
);

has 'attributes' => (
  is       => 'rw',
  isa      => HashRef,
  required => 0
);

around [qw/username password opendistro_security_roles backend_roles attributes/] => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    $self->$orig(@_);
    return ($self);
  }
  return ( $self->$orig );
};

sub api_spec {
  state $s = +{
    username => {
      encode_func => 'as_is',
      type        => 'path',
    },
    password => {
      encode_func => 'as_is',
      type        => 'body',
    },
    opendistro_security_roles => {
      encode_func => 'as_is',
      type        => 'body',
    },
    backend_roles => {
      encode_func => 'as_is',
      type        => 'body',
    },
    attributes => {
      encode_func => 'as_is',
      type        => 'body',
    },
  };
}

1;
