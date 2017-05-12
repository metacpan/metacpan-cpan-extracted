use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $sh1 = Set::Hash->new(one=>1,two=>2,three=>3);
my $sh2 = Set::Hash->new(one=>1,two=>2,three=>3);

my $h1 = $sh1->clear;
my %h2 = $sh2->clear;

eq_hash($h1,{},"scalar clear()");
ok(%h2 == (),"list clear()");
ok($sh1->length == 0,"length zero after clear()");
