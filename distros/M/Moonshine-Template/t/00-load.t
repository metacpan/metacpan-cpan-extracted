#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'UNIVERSAL::Object' );
    use_ok( 'Moonshine::Template' ) || print "Bail out!\n";
}

diag( "Testing Moonshine::Template $Moonshine::Template::VERSION, Perl $], $^X" );
