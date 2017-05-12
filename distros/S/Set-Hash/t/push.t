use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answer1 = {name=>"dan",age=>33,weight=>185};
my $answer2 = {name=>"dan",age=>33,weight=>185,hair=>undef};

my $sh1 = Set::Hash->new(qw/name dan age 33/);

$sh1->push("weight",185);

ok($sh1->length == 3);

$sh1->push("hair");

ok($sh1->length == 4);
