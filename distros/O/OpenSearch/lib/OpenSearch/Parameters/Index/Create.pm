package OpenSearch::Parameters::Index::Create;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str HashRef);
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

has 'mappings' => (
  is          => 'rw',
  isa         => HashRef,
);

has 'aliases' => (
  is          => 'rw',
  isa         => HashRef,
);

has 'wait_for_active_shards' => (
  is          => 'rw',
  isa         => Str,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/index settings mappings aliases wait_for_active_shards cluster_manager_timeout timeout/] => sub {
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
    },
    mappings => {
      encode_func => 'as_is',
      type        => 'body',
    },
    aliases => {
      encode_func => 'as_is',
      type        => 'body',
    },
    wait_for_active_shards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
