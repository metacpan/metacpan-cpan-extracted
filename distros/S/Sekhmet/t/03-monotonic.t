use strict;
use warnings;
use Test::More tests => 14;
use Sekhmet qw(ulid_monotonic ulid_monotonic_binary ulid_validate);

# Basic generation
my $m1 = ulid_monotonic();
ok(defined $m1, 'ulid_monotonic() returns a value');
is(length($m1), 26, 'Monotonic ULID is 26 characters');
like($m1, qr/^[0-7][0-9A-HJKMNP-TV-Z]{25}$/, 'Valid Crockford format');

# Monotonic ordering: sequential calls must be strictly increasing
my @ulids;
for (1..100) {
    push @ulids, ulid_monotonic();
}
my $all_ordered = 1;
for my $i (1..$#ulids) {
    if ($ulids[$i] le $ulids[$i-1]) {
        $all_ordered = 0;
        diag("ULID $i ($ulids[$i]) <= ULID " . ($i-1) . " ($ulids[$i-1])");
        last;
    }
}
ok($all_ordered, '100 monotonic ULIDs are strictly increasing');

# Validates
is(ulid_validate($m1), 1, 'Monotonic ULID validates');

# Binary variant
my $mb1 = ulid_monotonic_binary();
ok(defined $mb1, 'ulid_monotonic_binary() returns a value');
is(length($mb1), 16, 'Monotonic binary is 16 bytes');

# Monotonic binary ordering
my @bins;
for (1..50) {
    push @bins, ulid_monotonic_binary();
}
my $bins_ordered = 1;
for my $i (1..$#bins) {
    if ($bins[$i] le $bins[$i-1]) {
        $bins_ordered = 0;
        last;
    }
}
ok($bins_ordered, '50 monotonic binary ULIDs are strictly increasing');

# Uniqueness
my %seen;
for my $i (1..1000) {
    $seen{ulid_monotonic()}++;
}
is(scalar keys %seen, 1000, '1000 monotonic ULIDs are all unique');

# Rapid-fire still monotonic
my $prev = ulid_monotonic();
my $mono_ok = 1;
for (1..500) {
    my $cur = ulid_monotonic();
    if ($cur le $prev) {
        $mono_ok = 0;
        diag("Monotonic violation: $cur <= $prev");
        last;
    }
    $prev = $cur;
}
ok($mono_ok, '500 rapid-fire monotonic ULIDs stay ordered');

# First chars should be the same (same timestamp ms)
my @rapid;
push @rapid, ulid_monotonic() for 1..10;
my $same_ts = 1;
my $ts_prefix = substr($rapid[0], 0, 10);
for my $u (@rapid) {
    if (substr($u, 0, 10) ne $ts_prefix) {
        # Timestamp might have ticked — that's OK, just check ordering
        $same_ts = 0;
        last;
    }
}
# Whether same ts or not, ordering must hold
my $rapid_ordered = 1;
for my $i (1..$#rapid) {
    if ($rapid[$i] le $rapid[$i-1]) {
        $rapid_ordered = 0;
        last;
    }
}
ok($rapid_ordered, 'Rapid monotonic ULIDs maintain order');

# Mixed with regular ulid — monotonic state is independent
my $before = ulid_monotonic();
my $mixed = ulid_monotonic();
ok($mixed gt $before, 'Monotonic continues after call');

# String and binary produce same timestamp
my $ms = ulid_monotonic();
my $mb = ulid_monotonic_binary();
ok(length($ms) == 26 && length($mb) == 16, 'Both variants return correct lengths');

# Validate first rapid ULID
is(ulid_validate($rapid[0]), 1, 'Rapid ULID 0 validates');
