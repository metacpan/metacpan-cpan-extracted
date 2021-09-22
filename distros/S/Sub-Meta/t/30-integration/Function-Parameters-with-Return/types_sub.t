use Test2::V0;
use Test2::Require::Module 'Function::Parameters', '2.000003';
use Test2::Require::Module 'Function::Return', '0.14';

use Function::Parameters;
use Function::Return;
use Types::Standard -types;
use Types::Sub -types;

my $Sub = Sub[
    args    => [Int, Int],
    returns => Int,
];

fun add(Int $a, Int $b) :Return(Int) {
    return $a + $b
}

fun foo(Str $a, Int $b) :Return(Int) { }

fun bar(Int $a, Int $b) :Return(Str) { }

ok $Sub->check(\&add);
ok !$Sub->check(\&foo);
ok !$Sub->check(\&bar);

done_testing;
