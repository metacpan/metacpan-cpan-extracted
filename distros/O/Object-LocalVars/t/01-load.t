#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Object::LocalVars  

use Test::More tests => 1;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

BEGIN { use_ok("Object::LocalVars") };
