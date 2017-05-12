#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use_ok( "Socket::Netlink" );
use_ok( "IO::Socket::Netlink" );

use_ok( "Socket::Netlink::Generic" );
use_ok( "IO::Socket::Netlink::Generic" );
