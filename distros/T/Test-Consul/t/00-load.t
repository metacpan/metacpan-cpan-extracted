#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Test::Consul');

local $Test::Consul::VERSION = $Test::Consul::VERSION || 'from repo';
note("Test::Consul $Test::Consul::VERSION, Perl $], $^X");
