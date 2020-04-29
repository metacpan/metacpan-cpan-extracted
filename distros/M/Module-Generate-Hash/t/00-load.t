#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Module::Generate::Hash' ) || print "Bail out!\n";
}

diag( "Testing Module::Generate::Hash $Module::Generate::Hash::VERSION, Perl $], $^X" );
