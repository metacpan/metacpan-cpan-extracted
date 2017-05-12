#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Test::Spec' ) || print "Bail out!\n";
}

diag( "Testing Rex::Test::Spec $Rex::Test::Spec::VERSION, Perl $], $^X" );
