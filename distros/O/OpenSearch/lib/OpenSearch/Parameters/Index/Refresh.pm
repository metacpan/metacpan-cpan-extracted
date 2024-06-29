package OpenSearch::Parameters::Index::Refresh;
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

has 'ignore_unavailable' => (
  is          => 'rw',
  isa         => Bool,
);

has 'allow_no_indices' => (
  is          => 'rw',
  isa         => Bool,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/index ignore_unavailable allow_no_indices expand_wildcards/] => sub {
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
    ignore_unavailable => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
