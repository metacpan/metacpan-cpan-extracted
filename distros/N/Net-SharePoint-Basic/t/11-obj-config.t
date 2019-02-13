#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;
use Net::SharePoint::Basic;
use Test::Output qw(:stdout);

my $sp = Net::SharePoint::Basic->new({abcd => 123, xyz => 456});
is($sp->{config}{abcd}, 123, 'arbitrary option abcd set');
is($sp->{config}{xyz},  456, 'arbitrary option xyz set');

$sp = Net::SharePoint::Basic->new({config_file => 't/util.conf'});
isa_ok($sp, 'Net::SharePoint::Basic');
is_deeply(
	$sp->{config},
	{
		key1 => 'value1',
		key2 => 'value2',
		key3 => 'multiline value',
		key4 => 'value4',
		key5 => undef,
		key6 => 'another multiline value',
		token_file => $Net::SharePoint::Basic::DEFAULT_SHAREPOINT_TOKEN_FILE,
		max_log_size => $Net::SharePoint::Basic::MAX_LOG_SIZE,
		chunk_size => $Net::SharePoint::Basic::DEFAULT_CHUNK_SIZE,
		retries => $Net::SharePoint::Basic::DEFAULT_RETRIES,
	},
	"config file read correctly in constructor",
);
ok($sp->validate_config(), 'arbitrary config not validated');

$sp = Net::SharePoint::Basic->new({token_file => '/tmp/token', chunk_size => 1});
is($sp->{config}{token_file}, '/tmp/token', 'custom token file fallback');
is($sp->{config}{chunk_size}, 1, 'custom chunk size');
$sp = Net::SharePoint::Basic->new({config_file => 't/sharepoint.conf'});
for my $opt (keys %{$sp->{config}}) {
	stdout_like(
		sub { $sp->dump_config() },
		qr/\b$opt\s*$sp->{config}{$opt}\s+/m,
		"key $opt dumped correctly"
	);
}
ok(! $sp->validate_config(), 'test config validated');
