#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use PerlX::Range;

my $a = "a".."z";

ok($a->isa("PerlX::Range"));
ok("$a", '"a".."z"');
is($a->first, "a");
is($a->last,  "z");

done_testing;
