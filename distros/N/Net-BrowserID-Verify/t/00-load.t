#!perl -T

use strict;
use warnings;

use Test::More;
use Net::BrowserID::Verify;

diag( "Testing Net::BrowserID::Verify $Net::BrowserID::Verify::VERSION, Perl $], $^X" );

ok(1, "Successfully loaded Net::BrowserID::Verify via 'use'");

done_testing();
