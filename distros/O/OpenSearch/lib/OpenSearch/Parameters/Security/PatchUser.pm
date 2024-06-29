package OpenSearch::Parameters::Security::PatchUser;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str ArrayRef HashRef);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'username' => (
  is       => 'rw',
  isa      => Str,
  required => 1
);

has 'ops' => (
  is       => 'rw',
  isa      => ArrayRef [HashRef],
  required => 1
);

around [qw/username ops/] => sub {
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
    username => {
      encode_func => 'as_is',
      type        => 'path',
    },
    ops => {
      encode_func => 'as_is',
      type        => 'body',
      forced_body => 1,
    },
  };
}

1;
