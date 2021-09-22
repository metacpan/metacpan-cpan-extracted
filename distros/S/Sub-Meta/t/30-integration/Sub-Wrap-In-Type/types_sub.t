use Test2::V0;
use Test2::Require::Module 'Sub::WrapInType', '0.04';

use Sub::WrapInType;
use Types::Standard -types;
use Types::Sub -types;

my $Sub = Sub[
    args    => [Int, Int],
    returns => Int,
];

ok $Sub->check(wrap_sub([Int,Int] => Int, sub {}));
ok !$Sub->check(wrap_sub([Int] => Int, sub {}));

done_testing;
