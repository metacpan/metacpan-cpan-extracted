package OpenSearch::Parameters::Search::Count;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int HashRef);
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

has 'analyzer' => (
  is          => 'rw',
  isa         => Str,
);

has 'analyze_wildcard' => (
  is          => 'rw',
  isa         => Bool,
);

has 'default_operator' => (
  is          => 'rw',
  isa         => Str,
);

has 'df' => (
  is          => 'rw',
  isa         => Str,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Str,
);

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'lenient' => (
  is          => 'rw',
  isa         => Bool,
);

has 'min_score' => (
  is          => 'rw',
  isa         => Int,
);

has 'routing' => (
  is          => 'rw',
  isa         => Str,
);

has 'preference' => (
  is          => 'rw',
  isa         => Str,
);

has 'terminate_after' => (
  is          => 'rw',
  isa         => Int,
);

has 'query' => (
  is          => 'rw',
  isa         => HashRef,
);

around [
  qw/
    index allow_no_indices analyzer analyze_wildcard default_operator df
    expand_wildcards ignore_unavailable lenient min_score routing preference
    terminate_after query
    /
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
    analyzer => {
      encode_func => 'as_is',
      type        => 'url',
    },
    analyze_wildcard => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    default_operator => {
      encode_func => 'as_is',
      type        => 'url',
    },
    df => {
      encode_func => 'as_is',
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
    lenient => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    min_score => {
      encode_func => 'as_is',
      type        => 'body',
    },
    routing => {
      encode_func => 'as_is',
      type        => 'url',
    },
    preference => {
      encode_func => 'as_is',
      type        => 'url',
    },
    terminate_after => {
      encode_func => 'as_is',
      type        => 'body',
    },
    query => {
      encode_func => 'as_is',
      type        => 'body',
    }
  };
}

1;
