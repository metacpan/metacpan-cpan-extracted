use strict;
use warnings;

use Statistics::Simpson;

print "1..4\n";

my $p0 = Statistics::Simpson->new;
my $p1 = Statistics::Simpson->new(qw(a));

print defined $p0->index ?
  "not ok 1\n" : "ok 1\n";

print defined $p0->evenness ?
  "not ok 2\n" : "ok 2\n";

print $p1->index == 1 ?
  "ok 3\n" : "not ok 3\n";

print $p1->evenness == 1 ?
  "ok 4\n" : "not ok 4\n";


