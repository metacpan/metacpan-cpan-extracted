use Test2::V0;
use Test2::Require::Module 'Function::Return', '0.14';

use Function::Return;
use Types::Standard -types;
use Types::Sub -types;

my $Sub = Sub[
    returns => Int,
];

sub foo :Return(Int) { return 1 }
sub bar :Return(Str) { return "hello" }

ok $Sub->check(\&foo);
ok !$Sub->check(\&bar);

done_testing;
