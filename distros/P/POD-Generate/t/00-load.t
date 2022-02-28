#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POD::Generate' ) || print "Bail out!\n";
}

diag( "Testing POD::Generate $POD::Generate::VERSION, Perl $], $^X" );
