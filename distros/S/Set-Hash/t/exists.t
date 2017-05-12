use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $sh1 = Set::Hash->new(one=>1,two=>2,three=>3);

ok($sh1->exists("one") == 1);
ok($sh1->exists("blah") == 0);
ok($sh1->exists("one","two") == 1);
ok($sh1->exists("one","blah") == 0);
