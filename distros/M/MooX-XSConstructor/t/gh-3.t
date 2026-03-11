use lib 't/lib';
use Test::More;
use GH3;

isa_ok(GH3::Child2->new, 'GH3');
isa_ok(GH3::Child1->new, 'GH3');

done_testing;
