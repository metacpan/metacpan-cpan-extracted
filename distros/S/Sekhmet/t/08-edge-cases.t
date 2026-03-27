use strict;
use warnings;
use Test::More tests => 10;
use Sekhmet qw(ulid ulid_binary ulid_monotonic ulid_time ulid_time_ms
               ulid_to_uuid uuid_to_ulid ulid_compare ulid_validate);

# Edge: nil-like ULID (all zeros except valid format)
# "00000000000000000000000000" decodes to 16 zero bytes
my $nil = "00000000000000000000000000";
is(ulid_validate($nil), 1, 'Nil ULID is valid');
is(ulid_time($nil), 0, 'Nil ULID has timestamp 0');
is(ulid_time_ms($nil), 0, 'Nil ULID has 0 ms');

# Edge: max ULID
my $max = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ";
is(ulid_validate($max), 1, 'Max ULID is valid');
my $max_ms = ulid_time_ms($max);
ok($max_ms > 0, 'Max ULID has non-zero timestamp');

# Edge: compare nil < max
is(ulid_compare($nil, $max), -1, 'Nil < Max');
is(ulid_compare($max, $nil), 1, 'Max > Nil');

# Edge: UUID roundtrip preserves timestamp
my $u = ulid();
my $uuid = ulid_to_uuid($u);
my $back = uuid_to_ulid($uuid);
is(ulid_time_ms($u), ulid_time_ms($back), 'UUID roundtrip preserves timestamp');

# Edge: include_dir returns a valid path
my $dir = Sekhmet::include_dir();
ok(defined $dir, 'include_dir returns a value');
like($dir, qr/Sekhmet\/include$/, 'include_dir points to Sekhmet/include');
