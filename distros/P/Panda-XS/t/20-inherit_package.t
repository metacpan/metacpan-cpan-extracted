use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

{
    package Parent;
    sub func {1}
    package Child;
}

ok(!Child->isa('Parent'));

Panda::XS::Test::inherit_package('Child', 'Parent');

ok(Child->isa('Parent'), 'child now inherits parent');
ok(Child->func, 'inheritance works');

done_testing();
