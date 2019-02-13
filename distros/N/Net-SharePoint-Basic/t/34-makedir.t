#!perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use Test::More;

if (! $ENV{NET_SHAREPOINT_CONFIG}) {
	plan skip_all => 'SharePoint configuration is not defined';
	exit;
}

plan tests => 5;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});
my $folder = 'test-mkdir';
my $r = $sp->makedir({
	retries => 1,
}, $folder);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
my $list = $sp->list({path => '/'});
my $found = 0;
my $year = qx(date +%Y); chomp $year;
for my $item (@{$list}) {
	if ($item->{Name} eq $folder) {
		$found = 1;
		is($item->{ItemCount}, 0, 'length ok');
		like($item->{TimeLastModified}, qr/^$year/, 'year ok');
	}
}
ok($found, "$folder found");
