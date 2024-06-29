package OpenSearch::Parameters::Index::ClearCache;
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

has 'allow_no_indices' => (
  is          => 'rw',
  isa         => Bool,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Str,
);

has 'fielddata' => (
  is          => 'rw',
  isa         => Bool,
);

has 'fields' => (
  is          => 'rw',
  isa         => Str,
);

has 'file' => (
  is          => 'rw',
  isa         => Bool,
);

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'query' => (
  is          => 'rw',
  isa         => Bool,
);

has 'request' => (
  is          => 'rw',
  isa         => Bool,
);

around [qw/index allow_no_indices expand_wildcards fielddata fields file ignore_unavailable query request/] => sub {
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
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',  
    },
    fielddata => {
      encode_func => 'as_is',
      type        => 'url',
    },
    fields => {
      encode_func => 'as_is',
      type        => 'url',
    },
    file => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    query => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    request => {
      encode_func => 'encode_bool',
      type        => 'url',
    }
  };
}

1;
