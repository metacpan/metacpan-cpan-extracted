package OpenSearch::Parameters::Index::ImportDangling;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str Bool);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index_uuid' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

has 'accept_data_loss' => (
  is          => 'rw',
  isa         => Bool,
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/index_uuid accept_data_loss timeout cluster_manager_timeout/] => sub {
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
    index_uuid => {
      encode_func => 'as_is',
      type        => 'path',
    },
    accept_data_loss => {
      encode_func => 'encode_bool',
      type        => 'url',
    },
    timeout => {
      encode_func => 'as_is',
      type        => 'url',
    },
    cluster_manager_timeout => {
      encode_func => 'as_is',
      type        => 'url',
    }
  };
}

1;
