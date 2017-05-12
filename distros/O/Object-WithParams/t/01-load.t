#!/usr/bin/perl

# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok('Object::WithParams');
}

diag(
    "Testing Object::WithParams $Object::WithParams::VERSION, Perl $], $^X"
);
