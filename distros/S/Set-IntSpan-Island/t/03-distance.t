
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["1","",undef],
	    ["","1",undef],
	    ["","",undef],
	    ["1","1",-1],
	    ["1","2",1],
	    ["1-2","3",1],
	    ["1-2","3-4",1],
	    ["1-5","1-10",-5],
	    ["1-5,6","6-10",-1],
	    ["1-5","10-15",5],
	    ["1-5,10-15","5-9",-1],
	    ["1-5,10-15","6",1],
	    ["1-5,10-15","7",2],
	    ["1-5,10-15","7-9",1],
	    ["1-5,10-15","16-20",1],
	    ["1-5,10-15","17-20",2],
	    ["1-2,5-6,10-11,15-16","3",1],
	    ["1-2,5-6,10-11,15-16","3-4",1],
	    ["1-2,5-6,10-11,15-16","3-5",-1],
	    ["1-2,5-6,10-11,15-16","0",1],
	    ["1-2,5-6,10-11,15-16","20",4],
	    );

distance();

sub distance {
  for my $setdata (@sets) {
    my $set1 = Set::IntSpan::Island->new($setdata->[0]);
    my $set2 = Set::IntSpan::Island->new($setdata->[1]);
    my $expected = $setdata->[2];
    my $computed = $set1->distance($set2);
    my $input = join(" ",$set1->run_list,"distance",$set2->run_list);
    is($computed,$expected,$input);
  }
}
