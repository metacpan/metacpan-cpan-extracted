use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Button;
use Moonshine::Bootstrap::v3::Button;

moon_test(
    name => 'button',
    build => {
        class => 'Moonshine::Bootstrap::Component::Button',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button',
            args => {
                switch => 'success',
                data => 'Left',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success" type="button">Left</button>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'button',
            args => {
                switch => 'success',
                sizing => 'lg',
                data => 'Left',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success btn-lg" type="button">Left</button>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'button',
    build => {
        class => 'Moonshine::Bootstrap::v3::Button',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button',
            args => {
                switch => 'success',
                data => 'Left',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success" type="button">Left</button>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'button',
            args => {
                switch => 'success',
                sizing => 'lg',
                data => 'Left',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success btn-lg" type="button">Left</button>',
                }
            ],
        },
    ],
);

sunrise();

1;
