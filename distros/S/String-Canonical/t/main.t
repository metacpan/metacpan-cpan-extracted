#!/usr/bin/perl -w

use strict;
use Test;

open(F, "t/list") || die "list: $!";
our @tests = grep { chomp; ! /^#/ } <F>;
close F;

plan tests => scalar @tests;

# load module

use String::Canonical qw/cstr_cmp/;

# run through tests

ok(cstr_cmp(split '=')) || print STDERR " > $_\n" for @tests;
