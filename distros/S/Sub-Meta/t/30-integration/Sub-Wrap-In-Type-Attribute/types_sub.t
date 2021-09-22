use Test2::V0;
use Test2::Require::Module 'Sub::WrapInType::Attribute', '0.02';

use Sub::WrapInType::Attribute;
use Types::Standard -types;
use Types::Sub -types;

my $Sub = Sub[
    args    => [Int, Int],
    returns => Int,
];

sub add :WrapSub([Int,Int] => Int) {
    my ($a, $b) = @_;
    return $a + $b
}

sub double :WrapSub([Int] => Int) {
    my $a = shift;
    return $a * 2
}

ok $Sub->check(\&add);
ok !$Sub->check(\&double);

done_testing;
