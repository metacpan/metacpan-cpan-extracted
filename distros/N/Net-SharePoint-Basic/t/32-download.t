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

my $r = $sp->upload({
}, '/test-upload', $item);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');

my $content = $sp->download({}, '/test-upload');
is($content, $item, 'download ok');
my $item_file = 'nss' . rand();
my $save_file = $sp->download({save_file => $item_file}, '/test-upload');
is($save_file, $item_file, 'proper file returned');
is(-s $save_file, length($content), 'file looks correct');
unlink $item_file;

