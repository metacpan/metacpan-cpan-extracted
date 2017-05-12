#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::Methods";

# methods: fcn, args arrayref, result
my @methods = (
    [ "what_am_i", undef, "I am a t::Object::Methods" ],
    [ "greeting", [ 'DAGOLDEN' ], "Hello, DAGOLDEN" ]
);

plan tests => TC() + TM() * @methods;

my $o = test_constructor($class);
SKIP: {
    skip "because we don't have a $class object", TM() * @methods unless $o;
    test_methods( $o, $_ ) for @methods;
}


