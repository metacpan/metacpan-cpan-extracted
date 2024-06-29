package OpenSearch::Parameters::Cluster::UpdateSettings;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str HashRef Bool);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'flat_settings' => (
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

has 'persistent' => (
  is          => 'rw',
  isa         => HashRef,
  required    => 1,
);

has 'transient' => (
  is          => 'rw',
  isa         => HashRef,
  required    => 1,
);

around [qw/flat_settings cluster_manager_timeout timeout persistent transient/] => sub {
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
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    persistent => {
      encode_func => 'as_is',
      type        => 'body',
      forced_body => 0
    },
    transient => {
      encode_func => 'as_is',
      type        => 'body',
      forced_body => 0
    }
  };
}

1;
