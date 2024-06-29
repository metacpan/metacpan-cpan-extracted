package OpenSearch::Parameters::Cluster::GetSettings;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool Int);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'flat_settings' => (
  is          => 'rw',
  isa         => Bool,
);

has 'include_defaults' => (
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

around [qw/flat_settings include_defaults cluster_manager_timeout timeout/] => sub {
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
    flat_settings => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    include_defaults => {
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
    }
  };
}

1;
