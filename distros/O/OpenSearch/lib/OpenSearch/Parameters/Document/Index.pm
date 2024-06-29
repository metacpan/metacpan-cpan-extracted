package OpenSearch::Parameters::Document::Index;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int Enum HashRef);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

# create if _doc does not exist
has 'create' => (
  is          => 'rw',
  isa         => Bool,
);

has 'id' => (
  is          => 'rw',
  isa         => Str,
);

has 'doc' => (
  is          => 'rw',
  isa         => HashRef,
  required    => 1,
);

has 'if_seq_no' => (
  is          => 'rw',
  isa         => Int,
);

has 'if_primary_term' => (
  is          => 'rw',
  isa         => Int,
);

has 'op_type' => (
  is          => 'rw',
  isa         => Enum[qw(index create)],
);

has 'pipeline' => (
  is          => 'rw',
  isa         => Str,
);

has 'routing' => (
  is          => 'rw',
  isa         => Str,
);

has 'refresh' => (
  is          => 'rw',
  isa         => Enum[qw(true false wait_for)],
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'version' => (
  is          => 'rw',
  isa         => Int,
);

has 'version_type' => (
  is          => 'rw',
  isa         => Enum[qw(internal external external_gte)],
);

has 'wait_for_active_shards' => (
  is          => 'rw',
  isa         => Str,
);

has 'require_alias' => (
  is          => 'rw',
  isa         => Bool,
);

around [
  qw/
    index create id doc if_seq_no if_primary_term op_type pipeline routing refresh timeout
    version version_type wait_for_active_shards require_alias
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
    create => {
      encode_func => 'as_is',
      type        => 'path',
    },
    id => {
      encode_func => 'as_is',
      type        => 'path',
    },
    doc => {
      encode_func => 'as_is',
      type        => 'body',
    },
    if_seq_no => {
      encode_func => 'as_is',
      type        => 'body',
    },
    if_primary_term => {
      encode_func => 'as_is',
      type        => 'body',
    },
    op_type => {
      encode_func => 'as_is',
      type        => 'body',
    },
    pipeline => {
      encode_func => 'as_is',
      type        => 'body',
    },
    routing => {
      encode_func => 'as_is',
      type        => 'body',
    },
    refresh => {
      encode_func => 'as_is',
      type        => 'body',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    version => {
      encode_func => 'as_is',
      type        => 'url',
    },
    version_type => {
      encode_func => 'as_is',
      type        => 'url',
    },
    wait_for_active_shards => {
      encode_func => 'as_is',
      type        => 'url',
    },
    require_alias => {
      encode_func => 'encode_bool',
      type        => 'url',
    }
  };
}

1;
