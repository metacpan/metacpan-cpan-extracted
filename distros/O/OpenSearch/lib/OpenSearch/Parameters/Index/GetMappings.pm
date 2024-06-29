package OpenSearch::Parameters::Index::GetMappings;
use strict;
use warnings;
use feature qw(state);
use Types::Standard qw(Str);
use Types::Common::String qw(NonEmptyStr);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'index' => (
  is          => 'rw',
  isa         => NonEmptyStr,
  required    => 1,
);

has 'field' => (
  is          => 'rw',
  isa         => Str,
);

around [qw/index field/] => sub {
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
    field => {
      encode_func => 'as_is',
      type        => 'path',
    }
  };
}

1;
