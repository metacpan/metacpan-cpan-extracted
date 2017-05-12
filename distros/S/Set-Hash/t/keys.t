use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answer1 = ["one","two","three"];

my $sh = Set::Hash->new(one=>1,two=>2,three=>3);
my $keys = $sh->keys;
my @keys = $sh->keys;

eq_array([$sh->keys],$answer1,"basic keys() test");

ok("ARRAY" eq ref($keys),"ref type - scalar");

ok("ARRAY" eq ref(\@keys),"ref type - list");

eq_array($keys,$answer1,"lvalue scalar keys() test");

eq_array(\@keys,$answer1,"lvalue list keys() test");
