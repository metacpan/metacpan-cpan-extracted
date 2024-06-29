package OpenSearch::Parameters::Index::UpdateSettings;
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

has 'settings' => (
  is          => 'rw',
  isa         => HashRef,
);

has 'allow_no_indices' => (
  is          => 'rw',
  isa         => Bool,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Str,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'preserve_existing' => (
  is          => 'rw',
  isa         => Bool,
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/index settings allow_no_indices expand_wildcards cluster_manager_timeout preserve_existing timeout/] => sub {
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
    settings => {
      encode_func => 'as_is',
      type        => 'body',
      forced_body => 1,
    },
    allow_no_indices => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    preserve_existing => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
