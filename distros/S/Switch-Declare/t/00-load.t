#!perl
use 5.014;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Switch::Declare' ) || print "Bail out!\n";
}

ok( Switch::Declare->can('import'), 'Switch::Declare has import' );

diag( "Testing Switch::Declare $Switch::Declare::VERSION, Perl $], $^X" );
