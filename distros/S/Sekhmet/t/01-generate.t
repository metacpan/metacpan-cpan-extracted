use strict;
use warnings;
use Test::More tests => 13;
use Sekhmet qw(ulid ulid_monotonic ulid_validate);

# Basic generation
my $u1 = ulid();
ok(defined $u1, 'ulid() returns a value');
is(length($u1), 26, 'ULID is 26 characters');

# Crockford base32 character set
like($u1, qr/^[0-9A-HJKMNP-TV-Z]{26}$/, 'ULID uses Crockford alphabet');

# First char must be 0-7 (timestamp fits in 48 bits)
like($u1, qr/^[0-7]/, 'First character is 0-7 (48-bit timestamp)');

# Uniqueness
my %seen;
for my $i (1..1000) {
    my $u = ulid();
    $seen{$u}++;
}
is(scalar keys %seen, 1000, '1000 ULIDs are all unique');

# Multiple calls produce valid ULIDs
for my $i (1..5) {
    my $u = ulid();
    is(ulid_validate($u), 1, "Generated ULID $i validates");
}

# Monotonic ULIDs generated later always sort >= earlier
my $first = ulid_monotonic();
my $last;
for (1..100) { $last = ulid_monotonic(); }
ok($last ge $first, 'Later monotonic ULIDs sort >= earlier ones');

# Non-empty
ok($u1 ne '', 'ULID is not empty');

# Consistent format across calls
my $u2 = ulid();
like($u2, qr/^[0-7][0-9A-HJKMNP-TV-Z]{25}$/, 'Second ULID also valid format');
