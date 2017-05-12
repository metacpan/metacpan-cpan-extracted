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
    plan tests => 3 
}

ok( $mturk, "Created client");

my $hit = $mturk->newHIT();
ok( $hit, "Created HIT");

$mturk->deleteHIT( $hit->getFirst("HITId"), 1 );
ok( 1, "Deleted HIT" );
