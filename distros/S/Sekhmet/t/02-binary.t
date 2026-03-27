use strict;
use warnings;
use Test::More tests => 10;
use Sekhmet qw(ulid_binary);

# Basic generation
my $bin = ulid_binary();
ok(defined $bin, 'ulid_binary() returns a value');
is(length($bin), 16, 'Binary ULID is 16 bytes');

# Uniqueness
my $bin2 = ulid_binary();
isnt($bin, $bin2, 'Two binary ULIDs are different');

# Timestamp bytes are non-zero (current time > 0)
my $ts_byte = ord(substr($bin, 0, 1));
ok($ts_byte > 0 || ord(substr($bin, 1, 1)) > 0, 'Timestamp bytes are non-zero');

# Multiple calls produce 16-byte values
for my $i (1..5) {
    my $b = ulid_binary();
    is(length($b), 16, "Binary ULID $i is 16 bytes");
}

# Timestamp portion increases or stays same
my $b1 = ulid_binary();
my $b2 = ulid_binary();
my $ts1 = substr($b1, 0, 6);
my $ts2 = substr($b2, 0, 6);
ok($ts2 ge $ts1, 'Timestamp portion is non-decreasing');
