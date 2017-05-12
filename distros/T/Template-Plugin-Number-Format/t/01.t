#!/usr/bin/perl
# vim: set ft=perl:

use strict;
use POSIX qw(setlocale LC_ALL);
use Template::Test;
use Template::Plugin::Number::Format;

$Template::Test::DEBUG = 0;

my %vars = (
    "data1" => "1234567890",
    "data2" => "1029384756",
    "neg"   => "-30949043",
    "dec1"  => "1937849302.309498032",
    "dec2"  => "42.9",
);

setlocale(LC_ALL, "C");
test_expect(\*DATA, undef, \%vars);

__DATA__
-- test --
-- name round --
[% USE Number.Format -%]
[% dec1 | round %]
-- expect --
1937849302.31

-- test --
-- name format_number --
[% USE Number.Format -%]
[% data1 | format_number %]
-- expect --
1,234,567,890

-- test --
-- name format_number --
[% USE Number.Format -%]
[% dec2 | format_number(5) %]
-- expect --
42.9

-- test --
-- name format_number --
[% USE Number.Format -%]
[% dec2 | format_number(5, 5) %]
-- expect --
42.90000

-- test --
-- name format_negative --
[% USE Number.Format -%]
[% neg | format_negative %]
-- expect --
-30949043

-- test --
-- name format_negative --
[% USE Number.Format -%]
[% neg | format_negative("(x)") %]
-- expect --
(30949043)

-- test --
-- name format_negative --
[% USE Number.Format(NEG_FORMAT = "(x)") -%]
[% neg | format_negative %]
-- expect --
(30949043)

-- test --
-- name format_price --
[% USE Number.Format -%]
[% dec2 | format_price %]
-- expect --
USD 42.90

-- test --
-- name format_bytes --
[% USE Number.Format -%]
[% data1 | format_bytes %]
-- expect --
1.15G

-- test --
-- name format_bytes --
[% USE Number.Format(GIGA_SUFFIX = 'g') -%]
[% data1 | format_bytes %]
-- expect --
1.15g

-- test --
-- name unformat_number --
[% USE Number.Format -%]
[% data1 | format_number | unformat_number %]
-- expect --
-- process --
[% data1 %]

-- test --
-- name plugin test --
[% USE nf = Number.Format -%]
[% nf.format_number(data1) %]
-- expect --
-- process --
1,234,567,890

-- test --
-- name filter plugin test --
[% USE nf = Number.Format -%]
[% data1 | $nf %]
-- expect --
-- process --
1,234,567,890
