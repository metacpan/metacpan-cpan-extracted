#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Reactive::Core' ) || print "Bail out!\n";
}

diag( "Testing Reactive::Core $Reactive::Core::VERSION, Perl $], $^X" );
