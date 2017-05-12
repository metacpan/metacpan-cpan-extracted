# -*- perl -*-

use strict;
use Config;

BEGIN { $Set::IntSpan::integer = 1 }
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, " @_\n" }

print "1..1\n";

my $set = new Set::IntSpan '1_000_000_000_000-1_000_000_000_100';

for my $i (0..100)
{	
    insert $set 2e12+$i;
}

if ($Config{ivsize}==4)
{
    $set eq '1000000000000-1000000000100' or Not; OK 'use integer';
}
else
{
    OK '# SKIP not a 32-bit platform';
}

