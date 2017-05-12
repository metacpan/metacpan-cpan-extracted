#!/usr/bin/perl -w

use Test::More tests => 2;
use Net::SMS;

$sms = Net::SMS->new();

ok( defined $sms,				"new test");
ok( $sms->isa('Net::SMS'), 		"class test" );
