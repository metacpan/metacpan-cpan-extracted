use Test2::V0;

use Sub::WrapInType::Attribute pkg => 'Sample';

{
    package Sample;
    sub a :WrapSub([] => []) { }
    sub b :WrapMethod([] => []) { }
}

my $a = \&Sample::a;
my $b = \&Sample::b;

isa_ok $a, 'Sub::WrapInType';
isa_ok $b, 'Sub::WrapInType';

done_testing;
