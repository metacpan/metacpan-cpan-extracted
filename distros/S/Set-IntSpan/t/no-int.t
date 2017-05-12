# -*- perl -*-

use strict;
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

$set eq '1_000_000_000_000-1_000_000_000_100,2_000_000_000_000-2_000_000_000_100' or Not; OK 'no integer';
