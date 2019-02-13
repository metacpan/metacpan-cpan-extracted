#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

if (! $ENV{NET_SHAREPOINT_CONFIG}) {
	plan skip_all => 'SharePoint configuration is not defined';
	exit;
}

plan tests => 5;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});

my $item = 'x' x 1000;
my $year = qx(date +%Y); chomp $year;
my $r = $sp->upload({
}, '/test-upload', $item);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');

my $list = $sp->list({path => '/'});
my $found = 0;
for my $item (@{$list}) {
	if ($item->{Name} eq 'test-upload') {
		$found = 1;
		is($item->{Length}, 1000, 'length ok');
		like($item->{TimeLastModified}, qr/^$year/, 'year ok');
	}
}
ok($found, 'test-upload found');
