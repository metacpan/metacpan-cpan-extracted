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
    plan tests => 3; 
}

my $hit = $mturk->newHIT();
ok($hit, "CreateHIT");
$mturk->ForceExpireHIT( HITId => $hit->{HITId}[0] );
ok(1, "ForceExpireHIT");
$mturk->destroyHIT($hit);
ok(1, "Destroyed HIT");
