use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListedGroupItemText;
use Moonshine::Bootstrap::v3::ListedGroupItemText;

moon_test(
    name => 'listed_group_item_text',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListedGroupItemText',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item_text',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Hello World',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="list-group-item-text">Hello World</p>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'listed_group_item_text',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListedGroupItemText',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item_text',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Hello World',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="list-group-item-text">Hello World</p>'
                }
            ],
        },
    ],
);

sunrise();
