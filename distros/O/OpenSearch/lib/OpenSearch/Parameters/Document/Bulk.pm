package OpenSearch::Parameters::Document::Bulk;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str ArrayRef Bool Enum);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is  => 'rw',
  isa => Str,
);

has 'docs' => (
  is       => 'rw',
  isa      => ArrayRef,
  required => 1,
);

has 'pipeline' => (
  is  => 'rw',
  isa => Str,
);

has 'refresh' => (
  is  => 'rw',
  isa => Enum [qw(true false wait_for)],
);

has 'require_alias' => (
  is  => 'rw',
  isa => Bool,
);

has 'routing' => (
  is  => 'rw',
  isa => Str,
);

has 'timeout' => (
  is  => 'rw',
  isa => Str,
);

has 'wait_for_active_shards' => (
  is  => 'rw',
  isa => Str,
);

around [
  qw/
    index pipeline refresh require_alias routing timeout wait_for_active_shards docs
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
    docs => {
      encode_func => 'encode_bulk',
      type        => 'body',
      forced_body => 1,
    },
    pipeline => {
      encode_func => 'as_is',
      type        => 'url',
    },
    refresh => {
      encode_func => 'as_is',
      type        => 'url',
    },
    require_alias => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    routing => {
      encode_func => 'as_is',
      type        => 'body',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    wait_for_active_shards => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
