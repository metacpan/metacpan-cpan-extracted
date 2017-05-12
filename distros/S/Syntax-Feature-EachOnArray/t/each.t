#!perl

use strict;
use warnings;

use Test::More tests => 1;

use syntax 'each_on_array';

my @a = (qw/a b c/);
my $s = "";
while (my ($i, $e) = each @a) {
    $s .= $i . $e;
}
is($s, "0a1b2c");
