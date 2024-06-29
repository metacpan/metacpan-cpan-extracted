package OpenSearch::Parameters::Index::Split;
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

has 'target' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
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

has 'wait_for_completion' => (
  is          => 'rw',
  isa         => Bool,
);

has 'task_execution_timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'settings' => (
  is          => 'rw',
  isa         => HashRef,
);

has 'aliases' => (
  is          => 'rw',
  isa         => HashRef,
);

around [
  qw/index target wait_for_active_shards cluster_manager_timeout timeout wait_for_completion task_execution_timeout settings aliases/
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
    target => {
      encode_func => 'as_is',
      type        => 'path',
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
    },
    wait_for_completion => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    task_execution_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    settings => {
      encode_func => 'as_is',
      type        => 'body',
    },
    aliases => {
      encode_func => 'as_is',
      type        => 'body',
    }
  };
}

1;
