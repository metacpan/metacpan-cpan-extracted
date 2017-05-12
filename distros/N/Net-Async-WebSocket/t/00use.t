#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Net::Async::WebSocket" );
use_ok( "Net::Async::WebSocket::Protocol" );
use_ok( "Net::Async::WebSocket::Client" );
use_ok( "Net::Async::WebSocket::Server" );

done_testing;
