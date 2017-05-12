
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["1-5",0,"1-5"],
	    ["1-5",1,"-"],
	    ["1-5","1-5","-"],
	    ["1-5","1-10","-"],
	    ["1-5,7",6,"1-5,7"],
	    ["1-5,7","0,6","1-5,7"],
	    ["1-5,7","6-7","1-5"],
	    ["1-5,7","-1,6","1-5,7"],
	    ["1-5,7","-1,8","7"],
	    ["1-5,7",8,"7"],
	    ["1-5,7",0,"1-5"],
	    ["1-5,7-8",8,"1-5"],
	    ["1-5,7-8",9,"7-8"],
	    ["1-5,7-8",10,"7-8"],
	    ["1-5,7-8",-5,"1-5"],
	    ["1-5,7-8","-5--3","1-5"],
	    ["1-5,7-8","-5-3","7-8"],
	    ["1-5,8-9","6-7","1-5,8-9"],
	    ["1-5,10-15","6-7","1-5"],
	    ["1-5,10-15","(-)","-"],
	    ["1-5,10-15","1-15","-"],

	    );

nearest_island();

sub nearest_island {
  for my $setdata (@sets) {
    my $set = Set::IntSpan::Island->new($setdata->[0]);
    my $expected_set = Set::IntSpan::Island->new($setdata->[2]);
    my $island;
    if($setdata->[1] =~ /[-,]/) {
      $island = $set->nearest_island(Set::IntSpan->new($setdata->[1]));
    } else {
      $island = $set->nearest_island($setdata->[1]);
    }
    is($island->run_list,$expected_set->run_list,
       "nearest_island() on $set yielded $island but expected $expected_set"); 
  }
}

