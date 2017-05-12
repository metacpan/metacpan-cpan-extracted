use Test::Tester;

use Moonshine::Test qw/:all/;
use Test::MockObject;

moon_test(
    name         => 'build me, build me, build me',
    instructions => [
        {
            test => 'obj',
            meth => \&Moonshine::Test::_build_me,
            args => {
                class => 'Test::MockObject',
            },
            expected => 'Test::MockObject',
        },
        {
            test => 'obj',
            meth => \&Moonshine::Test::_build_me,
            args => {
                class => 'Test::MockObject',
            },
            expected => 'Test::MockObject'
        },
        {
            test => 'obj',
            meth => \&Moonshine::Test::_build_me,
            args => {
                class => 'Test::MockObject',
            },
            expected => 'Test::MockObject'
        },
    ],
);

sunrise(4, chan);

1;
