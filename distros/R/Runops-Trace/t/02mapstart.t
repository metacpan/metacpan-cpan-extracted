#!perl

use Runops::Trace;
BEGIN { Runops::Trace::enable_tracing() }

use Test::More tests => 1;

map { pass('map works') } '';
