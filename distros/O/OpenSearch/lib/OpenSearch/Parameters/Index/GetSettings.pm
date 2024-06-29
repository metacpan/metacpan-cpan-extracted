package OpenSearch::Parameters::Index::GetSettings;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is          => 'rw',
  isa         => Str,
);

has 'setting' => (
  is          => 'rw',
  isa         => Str,
);

has 'allow_no_indices' => (
  is          => 'rw',
  isa         => Bool,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Str,
);

has 'flat_settings' => (
  is          => 'rw',
  isa         => Bool,
);

has 'include_defaults' => (
  is          => 'rw',
  isa         => Bool,
);

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'local' => (
  is          => 'rw',
  isa         => Bool,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

around [
  qw/index setting allow_no_indices expand_wildcards flat_settings include_defaults ignore_unavailable local cluster_manager_timeout/
] => sub {
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
    index => {
      encode_func => 'as_is',
      type        => 'path',
    },
    setting => {
      encode_func => 'as_is',
      type        => 'path',
    },
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    flat_settings => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    include_defaults => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    local => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
