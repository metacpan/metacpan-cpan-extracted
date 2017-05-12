#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

if (!$ENV{MTURK_TEST_WRITABLE}) {
    plan skip_all => "Set environment variable MTURK_TEST_WRITABLE=1 to enable tests which have side-effects.";
}
else {
    plan tests => 1; 
}

my @hits;
for (1..4) {
    push(@hits, $mturk->newHIT());
}

my $hits = $mturk->SearchHITs->{HIT};
ok($#hits <= $#{$hits}, "SearchHITs");

foreach my $hit (@hits) {
    $mturk->destroyHIT($hit);
}

