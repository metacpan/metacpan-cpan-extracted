#!perl -T
use strict;
use Test::More tests => 1;

use_ok( 'POE::Component::NetSNMP::agent' ) || print "Bail out!\n";

diag( "Testing POE::Component::NetSNMP::agent $POE::Component::NetSNMP::agent::VERSION, Perl $], $^X" );
