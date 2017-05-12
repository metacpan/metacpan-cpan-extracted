
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["-",[]],
	    ["(-0",[qw{(-0}]],
	    ["0-)",[qw{0-)}]],
	    ["0,2-)",[qw{0 2-)}]],
	    ["1",[qw(1)]],
	    ["1-5",[qw(1-5)]],
	    ["1-5,7",[qw(1-5 7)]],
	    ["1-5,7-8",[qw(1-5 7-8)]],
	    ["1-5,7-8,10",[qw(1-5 7-8 10)]],
	    ["1-5,7-)",[qw{1-5 7-)}]],
	    ["(-1,3-5,7-)",[qw{(-1 3-5 7-)}]],
	    );

next_island();
prev_island();

sub next_island {
  for my $setdata (@sets) {
    my $set     = Set::IntSpan::Island->new($setdata->[0]);
    my @islands = map { Set::IntSpan::Island->new($_) } @{$setdata->[1]};
    my $n = 0;
    while(my $island = $set->next_island) {
      my $this_island = $set->current_island;
      my $expected_island = $islands[$n];
      if($expected_island) { 
	is($this_island->run_list,$expected_island->run_list,
	   "next_island() on $set yielded island $n as $this_island but expected $expected_island");
	$n++;
      } else {
	fail("next_island() should not have failed - big problem");
      }
    }
    ok(! defined $islands[$n],"next_island() island count wrong");
    ok(! defined $set->current_island,"next_island() current_island should be undefined, but is defined");
  }
}

sub prev_island {
  for my $setdata (@sets) {
    my $set     = Set::IntSpan::Island->new($setdata->[0]);
    my @islands = map { Set::IntSpan::Island->new($_) } @{$setdata->[1]};
    my $n = $set->num_islands-1;
    while(my $island = $set->prev_island) {
      my $this_island = $set->current_island;
      my $expected_island = $islands[$n];
      if($expected_island) { 
	is($this_island->run_list,$expected_island->run_list,
	   "prev_island() on $set yielded island $n as $this_island but expected $expected_island");
	$n--;
      } else {
	fail("prev_island() should not have failed - big problem");
      }
    }
    ok(! defined $set->current_island,"prev_island() current_island should be undefined, but is defined");
  }
}
