#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use Moose::Test::Case;

Moose::Test::Case->new->run_tests(
    after_last_pm => sub {
        no warnings qw/once redefine/;
        *Foo::is_postprocessed = sub { 1 };
        *Foo::_is_postprocessed = sub { 1 };
    },
)

