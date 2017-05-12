
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["-",0],
	    ["1",1],
	    ["1-5",1],
	    ["1-5,7",2],
	    ["1-5,7-8",2],
	    ["1-5,7-8,10",3],
	    ["1-5,7-8,10,12-)",4],
	    ["(--2,1-5,7-8,10,12-)",5],
	    ["(-)",1],
	    );

num_islands();

sub num_islands {
  for my $setdata (@sets) {
    my $set = Set::IntSpan::Island->new($setdata->[0]);
    my $expected = $setdata->[1];
    my $n = $set->num_islands;
    is($n,$expected,"num_islands() on $set returned $n but expected $expected");
  }
}
