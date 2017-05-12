#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

plan tests => 4;

my $class = "t::Object::Morbid::Sub";

my $ok = require_ok($class);

SKIP: {
    skip "because we didn't load $class object", 3
        unless $ok;
    my $o;
    lives_ok { $o = $class->new() } 
        "PREBUILD and BUILD methods should not be inherited";
    dies_ok  { $o->BUILD( inherit_test_flag => 1 ) }
        "Inherited BUILD should die";
    skip "because we didn't create a $class object", 1
        unless $o;
    lives_ok { $o = undef } 
        "DEMOLISH methods should not be inherited";
}

