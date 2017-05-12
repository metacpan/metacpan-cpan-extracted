#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Shell::GetEnv');
}

diag( "Testing Shell::GetEnv $Shell::GetEnv::VERSION, Perl $], $^X" );
