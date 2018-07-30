#!perl

use warnings;
use strict;

use Test::More tests => 1;

require_ok('Prometheus::Tiny');

local $Prometheus::Tiny::VERSION = $Prometheus::Tiny::VERSION || 'from repo';
note("Prometheus::Tny $Prometheus::Tiny::VERSION, Perl $], $^X");
