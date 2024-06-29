package OpenSearch::Parameters::Security::GetUser;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'username' => (
  is       => 'rw',
  isa      => Str,
  required => 1
);

around [qw/username/] => sub {
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
  };
}

1;
