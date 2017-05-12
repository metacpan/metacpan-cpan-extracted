
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["1","1",1],
	    ["1","2",0],
	    ["1-5","1-10",5],
	    ["1-5","-10-10",5],
	    ["1-5,6","6-10",1],
	    ["1,3,5-10","2,4-6",2],
	    ["1,3,5-10","2-4,9-10",3],
	    );

overlap();

sub overlap {
  for my $setdata (@sets) {
    my $set1 = Set::IntSpan::Island->new($setdata->[0]);
    my $set2 = Set::IntSpan::Island->new($setdata->[1]);
    my $input = join(" ",$set1->run_list,"overlap",$set2->run_list);
    my $expected = $setdata->[2];
    my $computed = $set1->overlap($set2);
    is($computed,$expected,$input);
  }
}
