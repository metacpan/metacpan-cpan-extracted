#!/usr/bin/perl

use strict;
use warnings;

use Test::More;# 'no_plan';
BEGIN { plan tests => 3 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus', qw{ tacacs_client }) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $client = tacacs_client(
	'host' => 'localhost',
	'key'  => 'test',
);

isa_ok($client, 'Net::TacacsPlus::Client');
