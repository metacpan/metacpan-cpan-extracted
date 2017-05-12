#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use_ok( "Socket::Netlink::Route" );
use_ok( "IO::Socket::Netlink::Route" );
