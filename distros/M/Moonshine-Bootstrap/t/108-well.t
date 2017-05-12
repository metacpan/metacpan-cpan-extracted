use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Well;
use Moonshine::Bootstrap::v3::Well;

moon_test(
    name => 'well',
    build => {
        class => 'Moonshine::Bootstrap::Component::Well',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'lg',
                data   => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well well-lg">...</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'sm',
                data   => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well well-sm">...</div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'well - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Well',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'lg',
                data   => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well well-lg">...</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'sm',
                data   => '...',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well well-sm">...</div>'
                }
            ],
        },
    ],
);

sunrise();
