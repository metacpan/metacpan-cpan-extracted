#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use t::Util;

use Readonly::Tiny qw/Readonly/;

Readonly my $x, 2;

is $x, 2,                   "Readonly assigns to scalar";
ok SvRO(\$x),               "Readonly makes scalar RO";

Readonly my @x, 1, 2, 3;

is_deeply \@x, [1, 2, 3],   "Readonly assigns to array";
ok SvRO(\@x),               "Readonly makes array RO";
ok SvRO(\$x[0]),            "Readonly makes array elem RO";

Readonly my %x, foo => 1;

is_deeply \%x, {foo => 1},  "Readonly assigns to hash";
ok SvRO(\%x),               "Readonly makes hash RO";
ok SvRO(\$x{foo}),          "Readonly makes hash elem RO";

done_testing;
