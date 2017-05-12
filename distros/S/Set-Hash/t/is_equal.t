use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $sh1 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh2 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh3 = Set::Hash->new(one=>4,two=>5,three=>6);

ok($sh1 == $sh2,"equals test");
isnt($sh1 == $sh3,"not equals test");
