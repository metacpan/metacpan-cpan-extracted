#!/usr/bin/perl
# 001module_load.t - basic test that the modules all load

use strict;
use warnings;

use Test::More tests => 6;                      # last test to print

require_ok( 'PiFlash::State' );
require_ok( 'PiFlash::Command' );
require_ok( 'PiFlash::Inspector' );
require_ok( 'PiFlash::MediaWriter' );
require_ok( 'PiFlash::Hook' );
require_ok( 'PiFlash' );

1;
