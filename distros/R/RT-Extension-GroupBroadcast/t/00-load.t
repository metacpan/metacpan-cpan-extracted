#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RT::Extension::GroupBroadcast' );
}

diag( "Testing RT::Extension::GroupBroadcast $RT::Extension::GroupBroadcast::VERSION, Perl $], $^X" );

