#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 2;
ok( $mturk, "Created client");

my $result = $mturk->GetReviewableHITsAll();
my $count = 0;
while (my $hit = $result->next) {
    printf STDERR "Hit %03d [%s]\n",
	    $count,
		$hit->{HITId}[0];
    $count++;
	if ($count > 300) {
	    last; # don't go on forever
	}
}

ok(1, "GetReviewableHITsAll");
