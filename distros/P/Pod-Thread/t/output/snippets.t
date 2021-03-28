#!/usr/bin/perl
#
# Test Pod::Thread behavior with various snippets.
#
# Copyright 2009, 2013, 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.012;
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Snippets qw(list_snippets test_snippet);

# Determine the number of tests and test that the module loads.
BEGIN {
    plan tests => scalar(list_snippets()) * 2 + 1;
    use_ok('Pod::Thread');
}

# Run all of the tests.
for my $snippet (list_snippets()) {
    test_snippet('Pod::Thread', $snippet);
}
