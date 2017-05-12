#!perl -T

use Test::More tests => 1;

BEGIN { use_ok( 'Net::GeoPlanet' ); }

diag( "Testing Net::GeoPlanet $Net::GeoPlanet::VERSION, Perl $], $^X" );
