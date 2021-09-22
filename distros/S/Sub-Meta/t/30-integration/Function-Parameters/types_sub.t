use Test2::V0;
use Test2::Require::Module 'Function::Parameters', '2.000003';

use Function::Parameters;
use Types::Standard -types;
use Types::Sub -types;

my $Sub = Sub[
    args => [Int, Int],
];

fun add(Int $a, Int $b) { return $a + $b }

fun double(Int $a) { return $a * 2 }

ok $Sub->check(\&add);
ok !$Sub->check(\&double);

done_testing;
