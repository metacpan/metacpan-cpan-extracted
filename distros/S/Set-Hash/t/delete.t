use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $sh1 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh2 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh3 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh4 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh5 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh6 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh7 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh8 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh9 = Set::Hash->new(one=>1,two=>2,three=>3);

my @deleted1 = $sh1->delete("one");
my @deleted2 = $sh2->delete("one","two");
my @deleted3 = $sh3->delete(qw/one two three/);
$sh4->delete("one");
$sh5->delete("one","two");
$sh6->delete(qw/one two three/);

eq_array(\@deleted1,[1]);
eq_array(\@deleted2,[1,2]);
eq_array(\@deleted3,[1,2,3]);
ok($sh1->length == 2, "length test");
ok($sh2->length == 1);
ok($sh3->length == 0);
ok($sh4->length == 2);
ok($sh5->length == 1);
ok($sh6->length == 0);
ok($sh7->delete("one")->length == 2);
ok($sh8->delete("one","two")->length == 1);
ok($sh9->delete(qw/one two three/)->length == 0);
