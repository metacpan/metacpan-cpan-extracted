use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListGroup;
use Moonshine::Bootstrap::v3::ListGroup;

moon_test(
    name => 'list_group',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'list_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        active => 1,
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-group"><li class="list-group-item active">Hello World</li></ul>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'list_group',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'list_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        active => 1,
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="list-group"><li class="list-group-item active">Hello World</li></ul>'
                }
            ],
        },
    ],
);



sunrise();
