use strict;
use warnings;
use Test::More tests => 12;
use Sekhmet qw(ulid ulid_binary ulid_time ulid_time_ms);

# Extract timestamp from string ULID
my $u = ulid();
my $ts = ulid_time($u);
ok(defined $ts, 'ulid_time() returns a value');
ok($ts > 1_000_000_000, 'Timestamp is a reasonable epoch (> year 2001)');
ok($ts < 10_000_000_000, 'Timestamp is not in the far future');

# Timestamp should be close to current time
my $now = time();
ok(abs($ts - $now) < 5, 'Timestamp is within 5 seconds of now');

# Extract milliseconds
my $ms = ulid_time_ms($u);
ok(defined $ms, 'ulid_time_ms() returns a value');
ok($ms > 1_000_000_000_000, 'Milliseconds is reasonable (> year 2001)');

# ms and seconds should be consistent
my $ts_from_ms = $ms / 1000;
ok(abs($ts_from_ms - $ts) < 1, 'ulid_time and ulid_time_ms are consistent');

# Extract from binary ULID
my $bin = ulid_binary();
my $ts_bin = ulid_time($bin);
ok(defined $ts_bin, 'ulid_time() works on binary input');
ok(abs($ts_bin - $now) < 5, 'Binary timestamp is within 5 seconds of now');

my $ms_bin = ulid_time_ms($bin);
ok(defined $ms_bin, 'ulid_time_ms() works on binary input');
ok($ms_bin > 1_000_000_000_000, 'Binary ms is reasonable');

# Consistency between string and binary from same generation
my $u2 = ulid();
my $ts2_str = ulid_time($u2);
ok($ts2_str > 0, 'Second ULID has positive timestamp');
