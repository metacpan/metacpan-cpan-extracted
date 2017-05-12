use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $sh1 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh2 = Set::Hash->new(foo=>"a",{bar=>"b",cab=>"c"});

ok($sh1->length == 3,"basic length() test");
ok($sh1->keys->length == 3, "chained length() test");

ok($sh2->length == 2,"length() with reference");
ok($sh2->keys->length == 2, "chained length() test, with reference");
