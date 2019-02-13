#!perl

# Copyright 2018 VMware, Inc.
# SPDX-License-Identifier: Artistic-1.0-Perl

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;
use Test::Output qw(:stderr :stdout);

use Net::SharePoint::Basic;

$ENV{NET_SHAREPOINT_DEBUG} = 0;
$ENV{NET_SHAREPOINT_VERBOSE} = 0;
stderr_is(sub { Net::SharePoint::Basic::verbose("test verbose") }, "", "no verbose test");
stderr_is(sub { Net::SharePoint::Basic::debug("test debug")     }, "", "no debug test");

$ENV{NET_SHAREPOINT_DEBUG} = 0;
$ENV{NET_SHAREPOINT_VERBOSE} = 1;
stderr_is(sub { Net::SharePoint::Basic::verbose("test verbose") }, "test verbose\n", "verbose test");
stderr_is(sub { Net::SharePoint::Basic::debug("test debug")     }, "", "no debug test");

$ENV{NET_SHAREPOINT_DEBUG} = 1;
$ENV{NET_SHAREPOINT_VERBOSE} = 0;
stderr_is(sub { Net::SharePoint::Basic::verbose("test verbose") }, "test verbose\n", "verbose/debug test");
stderr_is(sub { Net::SharePoint::Basic::debug("test debug")     }, "test debug\n", "debug test");
stderr_like(
	sub {
		Net::SharePoint::Basic::timedebug("test timedebug")
	}, qr/\S{3} \S{3}\s* \d{1,2} .*test timedebug/, "timedebug test"
);

$ENV{NET_SHAREPOINT_DEBUG} = 0;
$ENV{NET_SHAREPOINT_VERBOSE} = 0;

stdout_is(sub { Net::SharePoint::Basic::version(1) }, "$Net::SharePoint::Basic::VERSION\n", "version test");
