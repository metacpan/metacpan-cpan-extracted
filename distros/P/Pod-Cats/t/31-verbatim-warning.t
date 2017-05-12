#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Pod::Cats;
use Test::More 'no_plan';
use Test::Warnings ':all';

my $pc = Pod::Cats->new();
chomp(my @lines = <DATA>);
like(
    warning {; $pc->parse_lines(@lines) },
    qr/^Verbatim paragraph ended without blank line/,
    "Bad verbatim paragraph got warning"
);

__DATA__

This is normal text 1.

  This is verbatim.
This is normal text 5.
