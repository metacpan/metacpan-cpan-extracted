#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use_ok( "Socket::Netlink::Taskstats" );
use_ok( "IO::Socket::Netlink::Taskstats" );
