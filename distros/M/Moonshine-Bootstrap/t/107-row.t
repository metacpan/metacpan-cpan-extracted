use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Row;
use Moonshine::Bootstrap::v3::Row;

moon_test(
    name => 'row',
    build => {
        class => 'Moonshine::Bootstrap::Component::Row',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'row',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="row"></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'row',
    build => {
        class => 'Moonshine::Bootstrap::v3::Row',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'row',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="row"></div>'
                }
            ],
        },
    ],
);

sunrise();

1;
