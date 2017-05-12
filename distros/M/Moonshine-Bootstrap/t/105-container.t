use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Container;
use Moonshine::Bootstrap::v3::Container;

moon_test(
    name => 'container',
    build => {
        class => 'Moonshine::Bootstrap::Component::Container',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'container',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="container"></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'container v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Container',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'container',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="container"></div>',
                }
            ],
        },
    ],
);

sunrise();

1;
