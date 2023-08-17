#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Net::Async::HTTP::Server;
require Net::Async::HTTP::Server::Request;

require Plack::Handler::Net::Async::HTTP::Server;

pass "Modules loaded";
done_testing;
