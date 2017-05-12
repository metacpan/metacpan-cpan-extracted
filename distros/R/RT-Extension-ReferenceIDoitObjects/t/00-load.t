#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RT::Extension::ReferenceIDoitObjects' );
}

diag( "Testing RT::Extension::ReferenceIDoitObjects $RT::Extension::ReferenceIDoitObjects::VERSION, Perl $], $^X" );
