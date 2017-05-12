use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answer1 = {weight => 185};
my $answer2 = {age => 32};

my $sh1 = Set::Hash->new(qw/name dan age 33/);
my $sh2 = Set::Hash->new(qw/name dan age 33 weight 185/);

my $sh3 = Set::Hash->new(qw/name dan age 33/);
my $sh4 = Set::Hash->new(qw/name dan age 32/);

my %diff1 = $sh1->difference($sh2);
my %diff2 = $sh3->difference($sh4);

my $diff1 = $sh1->difference($sh2);
my $diff2 = $sh3->difference($sh4);

eq_hash(\%diff1,$answer1);
eq_hash(\%diff1,$answer1);
eq_hash($diff1,$answer1);
eq_hash($diff2,$answer2);

is($sh2->difference($sh1)->length,1,"length test");
is($sh4->difference($sh3)->length,1,"length test");
