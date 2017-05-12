use strict;
use warnings;

use Statistics::Shannon;

print "1..6\n";

my $p0 = Statistics::Shannon->new;
my $p1 = Statistics::Shannon->new(qw(a));

print $p0->index == 0 ?
  "ok 1\n" : "not ok 1\n";

print defined $p0->evenness ?
  "not ok 2\n" : "ok 2\n";

print $p1->index == 0 ?
  "ok 3\n" : "not ok 3\n";

print defined $p1->evenness ?
  "not ok 4\n" : "ok 4\n";

print !( eval '$p0->index(1)' ) &&
      $@ =~ /index: base cannot be <= 1.0/ ?
  "ok 5\n" : "not ok 5\n";

print !( eval '$p0->evenness(1)' ) &&
      $@ =~ /evenness: base cannot be <= 1.0/ ?
  "ok 6\n" : "not ok 6\n";

