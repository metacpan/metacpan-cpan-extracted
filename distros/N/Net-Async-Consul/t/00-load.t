#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Net::Async::Consul');

local $Net::Async::Consul::VERSION = $Net::Async::Consul::VERSION || 'from repo';
note("Net::Async::Consul $Net::Async::Consul::VERSION, Perl $], $^X");
