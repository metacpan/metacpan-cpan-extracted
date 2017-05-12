#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use PDF::Imposition::Schema2up;
use File::Spec::Functions;

plan tests => 1262;

diag "Testing the lower range";
for my $i (1..50) {
    my $sig = PDF::Imposition::Schema2up->_optimize_signature('50-100', $i);
    my $roundedup = round_to_four($i);
    if (($i % 4) == 0) {
        is($sig, $i);
    }
    is($sig, $roundedup);
    # print "$sig for $i pages\n";
}

open my $fh, "<", catfile(t => "sig-table-39-59.txt") or die $!;
for my $i (1..400) {
    my $lua = <$fh>;
    chomp $lua;
    my ($orig, $total, $signature, $lua_needed) = split / +/, $lua;
    die unless $orig == $i;
    my ($sig, $needed) = PDF::Imposition::Schema2up->_optimize_signature('39-59', $i);
    print "$needed for $i ($sig)\n" if $needed > 10;
    ok(($sig % 4) == 0);
    is($sig, $signature, "signature is $signature for $i pages");
    is($needed, $lua_needed, "needed $lua_needed for $i pages");
}
close $fh;

sub round_to_four {
    my $i = shift;
    return $i + ((4 - ($i % 4)) % 4);
}

