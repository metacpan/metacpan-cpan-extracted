
use strict;
use Test::More qw(no_plan);
use Set::IntSpan::Island 0.10;

my @runlists = (
		[[0],"0"],
		[[1],"1"],
		[[0,0],"0"],
		[[1,1],"1"],
		[[1,2],"1-2"],
		[[1,3],"1-3"],
		[[],"-"],
		);

new();
duplicate();
clone();

sub new {
  for my $rl (@runlists) {
    my $set      = Set::IntSpan::Island->new( @{$rl->[0]} );
    #diag(Dumper($set));
    my $input    = join(",",$rl->[0]);
    my $expected = $rl->[1];
    my $computed = $set->run_list;
    is($computed,$expected,"new $input -> $expected");
  }
}

sub duplicate {
  for my $rl (@runlists) {
    my $set      = Set::IntSpan::Island->new( @{$rl->[0]} );
    my $setc     = $set->duplicate();
    $set->insert(-1);
    my $input    = join("-",@{$rl->[0]});
    my $expected = $rl->[1];
    my $computed = $setc->run_list;
    is($computed,$expected,"duplicate $input -> $expected");
    isnt($set,$setc,"duplicate $set -> $setc");
  }
}

sub clone {
  for my $rl (@runlists) {
    my $set      = Set::IntSpan::Island->new( @{$rl->[0]} );
    my $setc     = $set->clone();
    $set->insert(-1);
    my $input    = join("-",@{$rl->[0]});
    my $expected = $rl->[1];
    my $computed = $setc->run_list;
    is($computed,$expected,"clone $input -> $expected");
    isnt($set,$setc,"clone $set -> $setc");
  }
}
