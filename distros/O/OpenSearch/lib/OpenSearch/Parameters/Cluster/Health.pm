package OpenSearch::Parameters::Cluster::Health;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int HashRef Enum);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is          => 'rw',
  isa         => Str,
);

has 'expand_wildcards' => (
  is          => 'rw',
  isa         => Enum[qw(all open closed hidden none)],
);

has 'level' => (
  is          => 'rw',
  isa         => Enum[qw(cluster indices shards awareness_attributes)],
);

has 'awareness_attributes' => (
  is          => 'rw',
  isa         => Str,
);

has 'local' => (
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

has 'wait_for_active_shards' => (
  is          => 'rw',
  isa         => Str,
);

has 'wait_for_nodes' => (
  is          => 'rw',
  isa         => Str,
);

has 'wait_for_events' => (
  is          => 'rw',
  isa         => Enum[qw(immediate urgent high normal low languid)],
);

has 'wait_for_no_relocating_shards' => (
  is          => 'rw',
  isa         => Bool,
);

has 'wait_for_no_initializing_shards' => (
  is          => 'rw',
  isa         => Bool,
);

has 'wait_for_status' => (
  is          => 'rw',
  isa         => Enum[qw(green yellow red)],
);

has 'weights' => (
  is          => 'rw',
  isa         => HashRef,
);

around [
  qw/index expand_wildcards level awareness_attributes local cluster_manager_timeout
    timeout wait_for_active_shards wait_for_nodes wait_for_events wait_for_no_relocating_shards
    wait_for_no_initializing_shards wait_for_status weights/
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
    expand_wildcards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    level => {
      encode_func => 'as_is',
      type        => 'url',
    },
    awareness_attributes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    local => {
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
    wait_for_active_shards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    wait_for_nodes => {
      encode_func => 'as_is',
      type        => 'url',
    },
    wait_for_events => {
      encode_func => 'as_is',
      type        => 'url',
    },
    wait_for_no_relocating_shards => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    wait_for_no_initializing_shards => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    wait_for_status => {
      encode_func => 'as_is',
      type        => 'url',
    },
    weights => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
