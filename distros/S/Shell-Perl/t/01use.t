#!perl -T

use Test::More tests => 1;

use_ok('Shell::Perl');

diag( "Testing Shell::Perl $Shell::Perl::VERSION, Perl $], $^X" );
