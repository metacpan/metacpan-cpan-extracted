#!perl

use strict;
use warnings;

use Test::More tests => 1;

use syntax 'keys_on_array';

my @a = (qw/a b c/);
my $s = join "", keys @a;
is($s, "012");
