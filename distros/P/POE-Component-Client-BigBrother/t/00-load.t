#!perl -T
use strict;
use Test::More tests => 1;

use_ok( 'POE::Component::Client::BigBrother' );

diag( "Testing POE::Component::Client::BigBrother $POE::Component::Client::BigBrother::VERSION, Perl $], $^X" );
