package TestOIDC::Logger;
use utf8;
use strict;
use warnings;

sub middleware {
  my ($class, $app) = @_;

  return sub {
    my ($env) = @_;

    # Discard log messages during tests
    $env->{'psgix.logger'} = sub {};

    return $app->($env);

  };
}

1;
