#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

plan tests => 1;

# Tests:
# * new

my $TEST_REPO = 't/data/repo';

my $sbokeeper = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);
isa_ok($sbokeeper, 'Slackware::SBoKeeper', 'new works');
