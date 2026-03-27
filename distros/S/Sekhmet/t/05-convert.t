use strict;
use warnings;
use Test::More tests => 15;
use Sekhmet qw(ulid ulid_binary ulid_to_uuid uuid_to_ulid ulid_time ulid_time_ms);

# ULID to UUID
my $u = ulid();
my $uuid = ulid_to_uuid($u);
ok(defined $uuid, 'ulid_to_uuid() returns a value');
is(length($uuid), 36, 'UUID is 36 characters');
like($uuid, qr/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
     'UUID has correct hyphenated format');

# UUID has version 7 stamp
my $ver_nibble = substr($uuid, 14, 1);
is($ver_nibble, '7', 'UUID has version 7');

# UUID has variant RFC4122 (high bits of byte 8 = 10xx)
my $var_nibble = hex(substr($uuid, 19, 1));
ok($var_nibble >= 8 && $var_nibble <= 0xB, 'UUID has RFC4122 variant');

# Roundtrip: ULID → UUID → ULID
my $roundtrip = uuid_to_ulid($uuid);
ok(defined $roundtrip, 'uuid_to_ulid() returns a value');
is(length($roundtrip), 26, 'Roundtrip ULID is 26 characters');

# Timestamp should be preserved through roundtrip
my $ts_orig = ulid_time_ms($u);
my $ts_round = ulid_time_ms($roundtrip);
is($ts_round, $ts_orig, 'Timestamp preserved through ULID→UUID→ULID roundtrip');

# Binary input for ulid_to_uuid
my $bin = ulid_binary();
my $uuid_from_bin = ulid_to_uuid($bin);
like($uuid_from_bin, qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'UUID from binary has correct format with v7 stamp');

# UUID → ULID from a known UUID string
my $uuid2 = ulid_to_uuid(ulid());
my $back = uuid_to_ulid($uuid2);
is(length($back), 26, 'uuid_to_ulid produces 26-char ULID');
like($back, qr/^[0-7][0-9A-HJKMNP-TV-Z]{25}$/, 'Converted ULID has valid format');

# Multiple roundtrips
for my $i (1..3) {
    my $orig = ulid();
    my $u2 = ulid_to_uuid($orig);
    my $rt = uuid_to_ulid($u2);
    my $ts1 = ulid_time_ms($orig);
    my $ts2 = ulid_time_ms($rt);
    is($ts2, $ts1, "Roundtrip $i preserves timestamp");
}

# Uppercase UUID input should also work
my $upper_uuid = uc(ulid_to_uuid(ulid()));
my $from_upper = uuid_to_ulid($upper_uuid);
is(length($from_upper), 26, 'uuid_to_ulid handles uppercase UUID');
