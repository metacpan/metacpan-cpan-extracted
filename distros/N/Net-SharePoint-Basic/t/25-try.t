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

plan tests => 2;

use Net::SharePoint::Basic;

my $sp = Net::SharePoint::Basic->new({config_file => $ENV{NET_SHAREPOINT_CONFIG}});
my $url = $sp->create_sharepoint_url({
	type => 'list',
	subtype => 'files',
	object => '.',
});
my $response = $sp->try({
	action  => 'list',
	retries => 1,
}, $url, %Net::SharePoint::Basic::DEFAULT_SHAREPOINT_POST_PARAMS,
);
ok($response, 'response received');
$url = $sp->create_sharepoint_url({
	type => 'list',
	subtype => 'files',
	object => 'deadbeef',
});
$Net::SharePoint::Basic::DEFAULT_SHAREPOINT_POST_PARAMS{Authorization} .= 'x';
$response = $sp->try({
	action  => 'list',
	retries => 1,
}, $url, %Net::SharePoint::Basic::DEFAULT_SHAREPOINT_POST_PARAMS,
);
ok(! $response, 'response not received with a bungled token');
