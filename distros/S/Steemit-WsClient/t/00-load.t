#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok( 'Steemit::WsClient' ) || print "Bail out!\n";

diag( "Testing Steemit $Steemit::WsClient::VERSION, Perl $], $^X" );

my $steem = Steemit::WsClient->new;

isa_ok( $steem, 'Steemit::WsClient', 'constructor will return a Steemit object');


