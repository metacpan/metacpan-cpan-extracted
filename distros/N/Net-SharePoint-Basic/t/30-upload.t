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

plan tests => 6;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});

my $item = 'x' x 1000;
my $r = $sp->upload({}, '/', $item);
ok(! $r, 'upload w/o filename failed');
$r = $sp->upload({}, '/test-upload', $item);

ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
my $item_file = 'nss' . rand();
$r = $sp->upload({ type   => 'file'}, '/',  $item_file);
ok(! $r, 'upload of non-existent file failed');
Net::SharePoint::Basic::write_file($item, $item_file);
$r = $sp->upload({ type   => 'file'}, '/',  $item_file);
ok($r, 'we got a result');
isa_ok($r, 'HTTP::Response');
unlink $item_file;
