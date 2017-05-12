
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["1-5",1,"1-5"],
	    ["1-5,7",1,"1-5"],
	    ["1-5,7",6,"-"],
	    ["1-5,7-8",7,"7-8"],
	    ["1-5,7",7,"7"],
	    ["1-5,8",7,"-"],
	    ["1-8",7,"1-8"],
	    ["1-8","7-8","1-8"],
	    ["1-5,7-8","7-8","7-8"],
	    ["1-5,8-9","7-8","8-9"],
	    ["1-5,8-9,11-15","9-11","8-9,11-15"],
	    ["1-5,8-9,11-15","16-20","-"],
	    ["1-5,8-9,11-15","","-"],
	    );

find_islands();

sub find_islands {
  for my $setdata (@sets) {
    my $set  = Set::IntSpan::Island->new($setdata->[0]);
    my $expected_set = Set::IntSpan::Island->new($setdata->[2]);
    my $island;
    if($setdata->[1] =~ /[,-]/) {
      $island = $set->find_islands(Set::IntSpan->new($setdata->[1]));
    } else {
      $island = $set->find_islands($setdata->[1]);
    }
    is($island->run_list,$expected_set->run_list,
       "find_islands() on $set yielded $island but expected $expected_set");
  }
}
