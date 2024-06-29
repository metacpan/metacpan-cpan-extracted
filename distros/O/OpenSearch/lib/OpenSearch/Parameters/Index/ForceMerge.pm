package OpenSearch::Parameters::Index::ForceMerge;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int);
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

has 'flush' => (
  is          => 'rw',
  isa         => Bool,
);

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'max_num_segments' => (
  is          => 'rw',
  isa         => Int,
);

has 'only_expunge_deletes' => (
  is          => 'rw',
  isa         => Bool,
);

has 'primary_only' => (
  is          => 'rw',
  isa         => Bool,
);

around [
  qw/index allow_no_indices expand_wildcards flush ignore_unavailable max_num_segments only_expunge_deletes primary_only/
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
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    flush => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    max_num_segments => {
      encode_func => 'as_is',
      type        => 'url',
    },
    only_expunge_deletes => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    primary_only => {
      encode_func => 'encode_bool',
      type        => 'url',
    }
  };
}

1;
