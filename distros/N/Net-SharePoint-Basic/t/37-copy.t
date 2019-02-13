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

plan tests => 9;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});
$ENV{NET_SHAREPOINT_DEBUG} = 1;
my $item = 'x' x 100000;
my $year = qx(date +%Y); chomp $year;
my $r = $sp->upload({
}, '/test-upload', $item);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');

my $folder = 'test-mkdir';
$r = $sp->makedir({
	retries => 1,
}, $folder);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
$r = $sp->copy({retries => 1}, '/test-upload', '/test-mkdir/tu');
ok($r, 'we got a result');
my $list = $sp->list({path => '/'});
my $found = 0;
for my $item (@{$list}) {
	if ($item->{Name} eq 'test-upload') {
		$found = 1;
	}
}
ok($found, "file copied, still there");
$list = $sp->list({path => $folder});
$found = 0;
for my $item (@{$list}) {
	if ($item->{Name} eq 'tu') {
		$found = 1;
	}
}
ok($found, "file copied and found");
$r = $sp->delete({
	retries => 1,
}, 'test-mkdir');
ok($r, 'we got a result');
$r = $sp->delete({
	retries => 1,
}, 'test-upload');
ok($r, 'we got a result');
