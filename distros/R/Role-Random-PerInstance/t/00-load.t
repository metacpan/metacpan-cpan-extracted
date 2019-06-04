#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Role::Random::PerInstance' ) || print "Bail out!\n";
}

diag( "Testing Role::Random::PerInstance $Role::Random::PerInstance::VERSION, Perl $], $^X" );
