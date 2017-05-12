
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my $set = Set::IntSpan->new("1-10");

my @sets = (
	    ["1-5",0,"1-5"],
	    ["1-5",1,"1-5"],
	    ["1-5,7",0,"1-5,7"],
	    ["1-5,7","(-0","1-5,7"],
	    ["1-5,7",1,"1-7"],
	    ["1-5,7",2,"1-7"],
	    ["1-5,7-8",1,"1-8"],
	    ["1-5,9-10",2,"1-5,9-10"],
	    ["1-5,9-10",3,"1-10"],
	    ["1-5,9-10,12-13,15",2,"1-5,9-15"],
	    ["1-5,9-10,12-13,15","1-2","1-5,9-15"],
	    ["1-5,9-10,12-13,15",3,"1-15"],
	    ["1-5,9-10,12,15,18,21","2-3","1-10,12-21"],
	    ["1-5,9-10,12,15,18,21","(-)","1-21"],
	    );

fill();

sub fill {
  for my $setdata (@sets) {
    my $set          = Set::IntSpan::Island->new($setdata->[0]);
    my $expected_set = Set::IntSpan::Island->new($setdata->[2]);
    my $fill_set;
    if($setdata->[1] =~ /[,-]/) {
      my $size_set = Set::IntSpan->new($setdata->[1]);
      $fill_set  = $set->fill($size_set);
    } else {
      $fill_set = $set->fill($setdata->[1]);
    }
    is($fill_set->run_list,$expected_set->run_list,
       "applying fill() to $set resulted in $fill_set but expected $expected_set");
  }
}
