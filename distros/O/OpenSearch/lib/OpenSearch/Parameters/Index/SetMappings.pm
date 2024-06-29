package OpenSearch::Parameters::Index::SetMappings;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool HashRef);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

has 'properties' => (
  is          => 'rw',
  isa         => HashRef,
  required    => 1,
);

has 'dynamic' => (
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

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'ignore_malformed' => (
  is          => 'rw',
  isa         => Bool,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'write_index_only' => (
  is          => 'rw',
  isa         => Bool,
);

around [
  qw/index properties dynamic allow_no_indices ignore_unavailable ignore_malformed cluster_manager_timeout write_index_only/
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
    properties => {
      encode_func => 'as_is',
      type        => 'body',
    },
    dynamic => {
      encode_func => 'as_is',
      type        => 'body',
    },
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_malformed => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    write_index_only => {
      encode_func => 'encode_bool',
      type        => 'url',
    }
  };
}

1;
