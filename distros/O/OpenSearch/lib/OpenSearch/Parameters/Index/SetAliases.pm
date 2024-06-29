package OpenSearch::Parameters::Index::SetAliases;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str ArrayRef);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'actions' => (
  is          => 'rw',
  isa         => ArrayRef,
);

has 'cluster_manager_timeout' => (
  is          => 'rw',
  isa         => Str,
);

has 'timeout' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/actions cluster_manager_timeout timeout/] => sub {
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
    actions => {
      encode_func => 'as_is',
      type        => 'body',
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
