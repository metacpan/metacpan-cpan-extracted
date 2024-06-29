package OpenSearch::Parameters::Security::ChangePassword;
use strict;
use warnings;
use feature         qw(state);
use Types::Standard qw(Str);
use Moo::Role;

with 'OpenSearch::Parameters';

has 'current_password' => (
  is  => 'rw',
  isa => Str,
);

has 'password' => (
  is  => 'rw',
  isa => Str,
);

around [qw/current_password password/] => sub {
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
    current_password => {
      encode_func => 'as_is',
      type        => 'body',
    },
    password => {
      encode_func => 'as_is',
      type        => 'body',
    },
  };
}

1;
