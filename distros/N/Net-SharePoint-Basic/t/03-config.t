#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;

use Net::SharePoint::Basic;
my $config = Net::SharePoint::Basic::read_config('t/util.conf');
is_deeply(
	$config,
	{
		key1 => 'value1',
		key2 => 'value2',
		key3 => 'multiline value',
		key4 => 'value4',
		key5 => undef,
		key6 => 'another multiline value',
	},
	"config read correctly",
);
