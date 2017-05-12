#!perl -I t/lib -w
use strict;
use Test::More;
plan skip_all =>'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' 
    unless $ENV{TEST_AUTHOR};

eval "use Test::Prereq";
plan skip_all => "Test::Prereq required for testing prerequisites" if $@;

prereq_ok(5.008005, "test prerequisites", [qw(My::TestUtils Template::Context)] );