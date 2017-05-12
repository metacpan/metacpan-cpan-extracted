######################################################################
# Test suite for Proc::Info::Environment
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use Proc::Info::Environment;

my $nof_tests = 1;

plan tests => $nof_tests;

SKIP: {

  if( !Proc::Info::Environment::os_supported() ) {
    skip Proc::Info::Environment::os_not_supported_error_message(), $nof_tests;
  }

  my $env = Proc::Info::Environment->new();
  my $data = $env->env( $$ );

  is $data->{PATH}, $ENV{PATH}, "env PATH for this process";
}
