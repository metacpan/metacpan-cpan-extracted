use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answer1 = {name=>"dan",age=>33};
my $answer2 = {name=>"dan"};

my $sh1 = Set::Hash->new(qw/name dan age 33 height 60/);
my $sh2 = Set::Hash->new(qw/name dan age 33 weight 185/);

my $sh3 = Set::Hash->new(qw/name dan age 33/);
my $sh4 = Set::Hash->new(qw/name dan age 32/);

my %inters1 = $sh1->intersection($sh2);
my %inters2 = $sh3->intersection($sh4);

my $inters1 = $sh1->intersection($sh2);
my $inters2 = $sh3->intersection($sh4);

eq_hash(\%inters1,$answer1);
eq_hash(\%inters1,$answer1);
eq_hash($inters1,$answer1);
eq_hash($inters2,$answer2);

is($sh1->intersection($sh2)->length,2,"length test");
is($sh3->intersection($sh4)->length,1,"length test");
