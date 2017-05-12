#!perl

use strict;
use warnings;

use Test::More tests => 1;

use syntax 'values_on_array';

my @a = (qw/a b c/);
my $s = join "", values @a;
is($s, "abc");
