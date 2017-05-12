
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["",10,"-"],
	    ["",0,"-"],
	    ["","(-)","-"],
	    ["","0-)","-"],
	    ["","5-10","-"],
	    ["","5-10,15-)","-"],
	    ["1-5",10,"1-5"],
	    ["1-5",2,"-"],
	    ["1-5","2-10","1-5"],
	    ["1-5","4,6","-"],
	    ["1-5","4-6","1-5"],
	    ["1-5,7","1","7"],
	    ["1-5,7","1-2","7"],
	    ["1-5,7","3-)","1-5"],
	    ["1-5,7-8,10","2-)","1-5,7-8"],
	    ["1-5,7-8,10,100-200","2-10","1-5,7-8"],
	    ["1-5,7-8,10,100-200","1-10","1-5,7-8,10"],
	    );

keep();

sub keep {
  for my $setdata (@sets) {
    my $set1 = Set::IntSpan::Island->new($setdata->[0]);
    my $expected_set = Set::IntSpan::Island->new($setdata->[2]);
    my $keep_set;
    if($setdata->[1] =~ /[,-]/ ) {
      my $size_set = Set::IntSpan->new($setdata->[1]);
      $keep_set = $set1->keep($size_set);
      my $keep_set2 = $set1->excise($size_set->complement);
      is($keep_set->run_list,$keep_set2->run_list,
	 "Applying keep() to $set1 using size filter $size_set did not return the same result as applying excise using complement.");
    } else {
      $keep_set = $set1->keep($setdata->[1]);
    }
    is($keep_set->run_list,$expected_set->run_list,
       "Applying keep() to $set1 using size filter $setdata->[1] returned $keep_set instead of $expected_set");
  }
}
