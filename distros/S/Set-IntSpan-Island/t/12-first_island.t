
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["-",undef],
	    ["(-)","(-)"],
	    ["(-0,2","(-0"],
	    ["0,2-)","0"],
	    ["0-)","0-)"],
	    ["1","1"],
	    ["1-5","1-5"],
	    ["1-5,7","1-5"],
	    ["1-5,7-8","1-5"],
	    ["1-5,7-8,10","1-5"],
	    );

first_island();

sub first_island {
   for my $setdata (@sets) {
    my $set      = Set::IntSpan::Island->new($setdata->[0]);
    my $expected = defined $setdata->[1] ? Set::IntSpan::Island->new($setdata->[1]) : $setdata->[1];
    if(defined $expected) {
      my $island = $set->first_island;
      is($island->run_list,$expected->run_list,
	 "first_island() on $set yielded $island but expected $expected");
    } else {
      ok(! defined $set->first_island,"first_island() on $set is defined but expected undefined.");
    }
  }
}
