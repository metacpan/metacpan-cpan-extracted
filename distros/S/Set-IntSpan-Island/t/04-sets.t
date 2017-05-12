
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @sets = (
	    ["",[qw()]],
	    ["(-)",[qw{(-)}]],
	    ["(-0,5-)",[qw{(-0 5-)}]],
	    ["0-)",[qw{0-)}]],
	    ["-5,0-)",[qw{-5 0-)}]],
	    ["-5--3,0-)",[qw{-5--3 0-)}]],
	    ["(-0",[qw{(-0}]],
	    ["(-0,5",[qw{(-0 5}]],
	    ["(-0,5-10",[qw{(-0 5-10}]],
	    ["1",[qw(1)]],
	    ["1-2",[qw(1-2)]],
	    ["1-2,4",[qw(1-2 4)]],
	    ["1-5,10-15",[qw(1-5 10-15)]],
	    ["1-2,5-6,10-11,15-16",[qw(1-2 5-6 10-11 15-16)]],
	    );

sets();

sub sets {
  for my $setdata (@sets) {
    my $set1 = Set::IntSpan::Island->new($setdata->[0]);
    my @sets = $set1->sets();
    my @expected_sets = map { Set::IntSpan::Island->new($_) } @{$setdata->[1]};
    my $nsets = @sets;
    my $nexpectedsets = @expected_sets;
    is($nsets,$nexpectedsets,
       "Split ".$set1->run_list." into $nsets sets but expected $nexpectedsets set");
    for my $i (0..@sets-1) {
      my $set = $sets[$i];
      my $expectedset = $expected_sets[$i];
      isa_ok($set,"Set::IntSpan::Island");
      isa_ok($expectedset,"Set::IntSpan::Island");
      my $set_runlist = $set->run_list;
      my $expectedset_runlist = $expectedset->run_list;
      is($set_runlist,$expectedset_runlist,"Extracted $set_runlist but expected $expectedset_runlist");
    }
  }
}
