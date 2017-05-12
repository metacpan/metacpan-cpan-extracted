#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Socket::Netlink;

ok( defined PF_NETLINK, 'PF_NETLINK defined' );
ok( defined AF_NETLINK, 'AF_NETLINK defined' );
