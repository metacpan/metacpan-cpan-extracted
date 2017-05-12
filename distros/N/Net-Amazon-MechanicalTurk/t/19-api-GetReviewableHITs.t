#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 2;
ok( $mturk, "Created client");

my $result = $mturk->GetReviewableHITs();
my $success = 1;
foreach my $hit (@{$result->{HIT}}) {
    if (!$hit->{HITId}[0]) {
        print STDERR "Found a hit without a hitid:\n", $hit->toString, "\n";
        $success = 0;
    }
}

ok($success, "GetReviewableHITs");
