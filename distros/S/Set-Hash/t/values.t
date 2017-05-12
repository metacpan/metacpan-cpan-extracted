use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answers1 = ["dan",33,185];

my $sh1 = Set::Hash->new(qw/name dan age 33 weight 185/);
my $vals = $sh1->values;
my @vals = $sh1->values;

eq_array([$sh1->values],$answer1,"basic vals() test");

ok("ARRAY" eq ref($vals),"ref type - scalar");

ok("ARRAY" eq ref(\@vals),"ref type - list");

eq_array($vals,$answer1,"lvalue scalar vals() test");

eq_array(\@vals,$answer1,"lvalue list vals() test");

ok($sh1->values->length == 3);
