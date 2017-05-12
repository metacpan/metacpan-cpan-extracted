use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

eval {
    Module::Requires->import('ClassA', '0.03');
};
like($@, qr/ClassA version 0.03 required--this is only version 0.02/);
ok(ClassA->can('package'));

eval {
    Module::Requires->import(
        'ClassA' => '0.03',
        'ClassB' => '0.10',
        'ClassC' => '0.30',
    );
};
like($@, qr/ClassA version 0.03 required--this is only version 0.02\nClassB version 0.10 required--this is only version 0.08\nClassC version 0.30 required--this is only version 0.12/);
eval {
    Module::Requires->import(
        'ClassC' => '0.99',
        'ClassA' => '0.10',
        'ClassB' => '0.30',
    );
};
like($@, qr/ClassC version 0.99 required--this is only version 0.12\nClassA version 0.10 required--this is only version 0.02\nClassB version 0.30 required--this is only version 0.08/);
ok(ClassB->can('package'));
ok(ClassC->can('package'));

eval {
    Module::Requires->import('ClassA', '0.02');
};
is($@, '');

eval {
    Module::Requires->import('ClassH', '0.02');
};
like($@, qr/ClassH does not define \$ClassH::VERSION--version check failed/);

done_testing;
