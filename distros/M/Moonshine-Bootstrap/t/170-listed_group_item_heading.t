use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListedGroupItemHeading;
use Moonshine::Bootstrap::v3::ListedGroupItemHeading;

moon_test(
    name => 'listed_group_item_heading',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListedGroupItemHeading',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item_heading',
            expected => 'Moonshine::Element',
            args   => {
                data => 'hello world',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<h4 class="list-group-item-heading">hello world</h4>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'listed_group_item_heading',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListedGroupItemHeading',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item_heading',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Hello World',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<h4 class="list-group-item-heading">Hello World</h4>'
                }
            ],
        },
    ],
);

sunrise();
