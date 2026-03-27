#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use Sekhmet qw(ulid ulid_binary ulid_monotonic ulid_monotonic_binary
               ulid_to_uuid uuid_to_ulid ulid_validate ulid_compare);

print "Sekhmet ULID Benchmark\n";
print "=" x 50, "\n";
print "Perl $]\n\n";

my $sample_ulid = ulid();
my $sample_uuid = ulid_to_uuid($sample_ulid);
my $sample_bin  = ulid_binary();
my $sample_ulid2 = ulid();

print "Sample ULID: $sample_ulid\n";
print "Sample UUID: $sample_uuid\n\n";

print "--- Generation ---\n";
cmpthese(-3, {
    'ulid()'                  => sub { ulid() },
    'ulid_binary()'           => sub { ulid_binary() },
    'ulid_monotonic()'        => sub { ulid_monotonic() },
    'ulid_monotonic_binary()' => sub { ulid_monotonic_binary() },
});

print "\n--- Utilities ---\n";
cmpthese(-3, {
    'ulid_to_uuid()'  => sub { ulid_to_uuid($sample_ulid) },
    'uuid_to_ulid()'  => sub { uuid_to_ulid($sample_uuid) },
    'ulid_validate()'  => sub { ulid_validate($sample_ulid) },
    'ulid_compare()'   => sub { ulid_compare($sample_ulid, $sample_ulid2) },
});

print "\n--- vs Pure Perl ---\n";
sub pp_ulid {
    my @chars = ('0'..'9', 'A'..'H', 'J', 'K', 'M', 'N', 'P'..'T', 'V'..'Z');
    my $ts = int(time() * 1000);
    my $out = '';
    for my $i (reverse 0..9) {
        $out = $chars[$ts % 32] . $out;
        $ts = int($ts / 32);
    }
    for (1..16) {
        $out .= $chars[int(rand(32))];
    }
    return $out;
}

cmpthese(-3, {
    'XS ulid()'       => sub { ulid() },
    'Pure Perl ulid()' => sub { pp_ulid() },
});
