#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('String::Interpolate::RE');
}

diag( "Testing String::Interpolate::RE $String::Interpolate::RE::VERSION, Perl $], $^X" );
