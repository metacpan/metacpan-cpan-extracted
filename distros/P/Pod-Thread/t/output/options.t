#!/usr/bin/perl
#
# Test special cases of Pod::Thread option handling.
#
# Copyright 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use warnings;

use Test::More tests => 2;

require_ok('Pod::Thread');

# If the title is undef, that should be treated the same as not passing in a
# title in the constructor options.
my $podthread = Pod::Thread->new(title => undef);
my $output;
$podthread->output_string(\$output);
$podthread->parse_string_document("=head1 NAME\n\nfoo - b\n");
is(
    $output,
    "\\heading[foo][]\n\n\\h1[foo]\n\n\\class(subhead)[(b)]\n\n\\signature\n",
    'undef title ignored',
);
