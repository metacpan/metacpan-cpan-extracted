#!perl

use warnings;
use strict;

use Test::More tests => 1;

require_ok('Prometheus::Tiny::Shared');

local $Prometheus::Tiny::Shared::VERSION = $Prometheus::Tiny::Shared::VERSION || 'from repo';
note("Prometheus::Tny $Prometheus::Tiny::Shared::VERSION, Perl $], $^X");
