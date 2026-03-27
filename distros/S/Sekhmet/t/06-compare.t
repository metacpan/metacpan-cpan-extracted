use strict;
use warnings;
use Test::More tests => 12;
use Sekhmet qw(ulid ulid_monotonic ulid_compare);

# Equal comparison
my $u = ulid();
is(ulid_compare($u, $u), 0, 'Same ULID compares equal');

# Ordering: random ULIDs return valid result
my $ua = ulid();
my $ub = ulid();
my $cmp = ulid_compare($ua, $ub);
ok($cmp == -1 || $cmp == 0 || $cmp == 1, 'ulid_compare returns -1, 0, or 1');

# Monotonic ULIDs are strictly ordered
my $mono_a = ulid_monotonic();
my $mono_b = ulid_monotonic();
is(ulid_compare($mono_a, $mono_b), -1, 'Earlier monotonic < later monotonic');
is(ulid_compare($mono_b, $mono_a), 1, 'Later monotonic > earlier monotonic');

# String vs string with known values
my $s1 = "00000000000000000000000000";
my $s2 = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ";
is(ulid_compare($s1, $s2), -1, 'Min ULID < max ULID');
is(ulid_compare($s2, $s1), 1, 'Max ULID > min ULID');
is(ulid_compare($s1, $s1), 0, 'Min ULID == Min ULID');

# Antisymmetric
my $u1 = ulid_monotonic();
my $u2 = ulid_monotonic();
my $c1 = ulid_compare($u1, $u2);
my $c2 = ulid_compare($u2, $u1);
ok($c1 == -$c2 || ($c1 == 0 && $c2 == 0), 'Comparison is antisymmetric');

# Transitivity via sort
my @sorted = sort { ulid_compare($a, $b) } map { ulid_monotonic() } 1..10;
my $transitive = 1;
for my $i (0..$#sorted-1) {
    if (ulid_compare($sorted[$i], $sorted[$i+1]) > 0) {
        $transitive = 0;
        last;
    }
}
ok($transitive, 'Sorted monotonic ULIDs maintain ordering');

# Self-comparison
my $self = ulid();
is(ulid_compare($self, $self), 0, 'Self-comparison is always 0');

# Edge: compare minimum values
is(ulid_compare("00000000000000000000000000", "00000000000000000000000000"), 0,
   'Two zero ULIDs are equal');

# Edge: compare max values
is(ulid_compare("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "7ZZZZZZZZZZZZZZZZZZZZZZZZZ"), 0,
   'Two max ULIDs are equal');
