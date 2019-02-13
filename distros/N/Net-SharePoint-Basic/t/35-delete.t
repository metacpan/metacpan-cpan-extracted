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

plan tests => 15;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});

my $item = 'x' x 100000;
my $year = qx(date +%Y); chomp $year;
my $r = $sp->upload({
}, '/test-upload', $item);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');

$r = $sp->delete({
	retries => 1,
}, 'test-upload');
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
my $found = 0;
my $list = $sp->list({path => '/'});
for my $item (@{$list}) {
	if ($item->{Name} eq 'test-upload') {
		$found = 1;
		last;
	}
}
ok(! $found, 'test-upload NOT found');

$sp->{config}{chunk_size} = 30000;
$r = $sp->upload({
}, '/test-upload-chunks', $item);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');

$r = $sp->delete({
	retries => 1,
}, 'test-upload-chunks');
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
$found = 0;
$list = $sp->list({path => '/'});
for my $item (@{$list}) {
	if ($item->{Name} eq 'test-upload-chunks') {
		$found = 1;
		last;
	}
}
ok(! $found, 'test-upload-chunks NOT found');

my $folder = 'test-mkdir';
$r = $sp->makedir({
	retries => 1,
}, $folder);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
$r = $sp->delete({
	retries => 1,
}, $folder);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
$list = $sp->list({path => '/'});
$found = 0;
for my $item (@{$list}) {
	if ($item->{Name} eq $folder) {
		$found = 1;
		last;
	}
}
ok(! $found, "$folder NOT found");
