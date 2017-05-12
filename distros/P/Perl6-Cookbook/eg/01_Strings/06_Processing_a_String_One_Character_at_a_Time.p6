#!/usr/bin/perl6
use v6;

my @a = split('', "abc");        # // is disallowed in Perl 6
@a[0].say;                       # a
@a[1].say;                       # b
@a[2].say;                       # c


# TODO unpack solution as well