use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Ul;
use Moonshine::Bootstrap::v3::Ul;

moon_test(
    name => 'ul',
    build => {
        class => 'Moonshine::Bootstrap::Component::Ul',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'ul',
            args => {
                inline => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-inline"></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'ul',
            args => {
                unstyle => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-unstyled"></ul>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'ul - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Ul',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'ul',
            args => {
                inline => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-inline"></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'ul',
            args => {
                unstyle => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-unstyled"></ul>',
                }
            ],
        },
    ],
);

sunrise();

1;
