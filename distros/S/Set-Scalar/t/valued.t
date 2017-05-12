use Set::Scalar::Valued;

use strict;

print "1..9\n";

my $ns = Set::Scalar::Valued->new();

print $ns->is_null ? "ok 1\n" : "not ok 1\n";
print $ns->size == 0 ? "ok 2\n" : "not ok 2\n";

print $ns->null->is_null  ? "ok 3\n" : "not ok 4\n";
print $ns->null->size == 0 ? "ok 4\n" : "not ok 4\n";

my $vs = Set::Scalar::Valued->new(a=>1);

print $vs->is_null ? "not ok 5\n" : "ok 5\n";
print $vs->size == 0 ? "not ok 6\n" : "ok 6\n";

print $vs->null->is_null  ? "ok 7\n" : "not ok 7\n";
print $vs->null->size == 0 ? "ok 8\n" : "not ok 8\n";

my $a = Set::Scalar::Valued->new(a=>1);
my $b = Set::Scalar::Valued->new(a=>1, b=>2);
my $c = $a-$b;
print "$c" eq "()" ? "ok 9\n" : "not ok 9\n";




