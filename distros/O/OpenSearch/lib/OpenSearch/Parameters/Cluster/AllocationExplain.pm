package OpenSearch::Parameters::Cluster::AllocationExplain;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'current_node' => (
  is          => 'rw',
  isa         => Str,
);

has 'index' => (
  is          => 'rw',
  isa         => Str,
);

has 'primary' => (
  is          => 'rw',
  isa         => Bool,
);

has 'shard' => (
  is          => 'rw',
  isa         => Int,
);

has 'include_disk_info' => (
  is          => 'rw',
  isa         => Bool,
);

has 'include_yes_decisions' => (
  is          => 'rw',
  isa         => Bool,
);

around [qw/current_node index primary shard include_disk_info include_yes_decisions/] => sub {
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
    current_node => {
      encode_func => 'as_is',
      type        => 'body',
    },
    index => {
      encode_func => 'as_is',
      type        => 'body',
    },
    primary => {
      encode_func => 'encode_bool',
      type        => 'body',
    },
    shard => {
      encode_func => 'as_is',
      type        => 'body',
    },
    include_disk_info => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    include_yes_decisions => {
      encode_func => 'encode_bool',
      type        => 'url',
    }
  };
}

1;
