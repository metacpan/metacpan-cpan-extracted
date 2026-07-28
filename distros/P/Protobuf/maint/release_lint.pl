#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;

require Protobuf;
my $v = $Protobuf::VERSION;
if (!defined $v || !length $v) {
    die "RELEASE LINT ERROR: VERSION not set in Protobuf.pm\n";
}

open my $fh, '<', 'Changes' or die "RELEASE LINT ERROR: Cannot read Changes: $!\n";
my $has_entry = 0;
while (<$fh>) {
    if (/^\Q$v\E\b/) {
        $has_entry = 1;
        last;
    }
}
close $fh;

if (!$has_entry) {
    die "RELEASE LINT ERROR: No Changes entry found for version $v in Changes file!\n";
}

my @mismatches;
find(sub {
    return unless /\.pm$/;
    return if $File::Find::dir =~ m{lib/(?:Conformance|Protobuf_test_messages|Google)};
    open my $pm, '<', $_ or return;
    while (<$pm>) {
        if (/our\s+\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
            if ($1 ne $v) {
                push @mismatches, "$File::Find::name (expected $v, found $1)";
            }
        }
    }
    close $pm;
}, 'lib');

if (@mismatches) {
    die "RELEASE LINT ERROR: Version mismatches found:\n  " . join("\n  ", @mismatches) . "\n";
}

print "RELEASE LINT PASS: Version $v verified in Changes and across all lib/ modules.\n";
exit 0;
