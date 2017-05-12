
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["-",0,undef],
	    ["-",1,undef],
	    ["-",-1,undef],
	    ["(-)",0,"(-)"],
	    ["(-0,2-)",0,"(-0"],
	    ["(-0,2-)",1,"2-)"],
	    ["(-0,2-)",-1,"2-)"],
	    ["(-0,2-)",2,undef],
	    ["1",0,"1"],
	    ["1",1,undef],
	    ["1",-1,"1"],
	    ["1-5",0,"1-5"],
	    ["1-5,7",0,"1-5"],
	    ["1-5,7",1,"7"],
	    ["1-5,7-8",0,"1-5"],
	    ["1-5,7-8",1,"7-8"],
	    ["1-5,7-8,10",2,"10"],
	    ["1-5,7-8,10",3,undef],
	    );

at_island();

sub at_island {
  for my $setdata (@sets) {
    my $set    = Set::IntSpan::Island->new($setdata->[0]);
    my $n      = $setdata->[1];
    my $expected = $setdata->[2] ? Set::IntSpan::Island->new($setdata->[2]) : $setdata->[2];
    my $island = $set->at_island($n);
    if($expected) {
      is($island->run_list,$expected->run_list,
	 "at_island() on set $set at $n yielded $island but expected $expected");
    } else {
      ok(! defined $island,"at_island() is defined but expected not defined");
    }
  }
}
