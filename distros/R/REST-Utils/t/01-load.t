#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {

    use_ok('REST::Utils', (':all'));

}

diag(
    "Testing REST::Utils $REST::Utils::VERSION, Perl $], $^X\n",
);
