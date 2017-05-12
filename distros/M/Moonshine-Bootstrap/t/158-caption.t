use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Caption;
use Moonshine::Bootstrap::v3::Caption;

moon_test(
    name => 'caption',
    build => {
        class => 'Moonshine::Bootstrap::Component::Caption',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'caption',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="caption"></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'caption',
    build => {
        class => 'Moonshine::Bootstrap::v3::Caption',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'caption',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="caption"></div>',
                }
            ],
        },
    ],
);

sunrise();
