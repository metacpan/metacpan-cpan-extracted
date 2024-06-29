package OpenSearch::Parameters::Security::CreateRole;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str ArrayRef);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'role' => (
  is       => 'rw',
  isa      => Str,
  required => 1
);

# Actually only one of these is required so we dont do any local checks
has 'cluster_permissions' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 0
);

has 'index_permissions' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 0
);

has 'tenant_permissions' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 0
);

around [qw/role cluster_permissions index_permissions tenant_permissions/] => sub {
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
    role => {
      encode_func => 'as_is',
      type        => 'path',
    },
    cluster_permissions => {
      encode_func => 'as_is',
      type        => 'body',
    },
    index_permissions => {
      encode_func => 'as_is',
      type        => 'body',
    },
    tenant_permissions => {
      encode_func => 'as_is',
      type        => 'body',
    },
  };
}

1;
