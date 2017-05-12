#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Module::ScanDeps ();

my @deps = Module::ScanDeps::_get_preload('Event.pm');
ok(grep {$_ eq 'Event/idle.pm'} @deps) or diag(join(', ',@deps));

