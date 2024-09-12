#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Net::Async::WebSocket;
require Net::Async::WebSocket::Protocol;
require Net::Async::WebSocket::Client;
require Net::Async::WebSocket::Server;

pass( 'Modules loaded' );
done_testing;
