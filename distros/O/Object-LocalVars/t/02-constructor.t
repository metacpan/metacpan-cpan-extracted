#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

plan tests => 2 * TC();

test_constructor("t::Object::Trivial");
test_constructor("t::Object::CustomNew");


