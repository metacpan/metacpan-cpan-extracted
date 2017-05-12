use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListedGroup;
use Moonshine::Bootstrap::v3::ListedGroup;

moon_test(
    name => 'listed_group',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListedGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        href   => '#',
                        active => 1,
                    }
                ],
            },           
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><a class="list-group-item active" href="#">Hello World</a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        button => 1,
                    }
                ],
            },           
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><button class="list-group-item" type="button">Hello World</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        active => 1,
                        href   => '#',
                        children  => [
                            {
                                action => 'listed_group_item_heading',
                                data   => 'List group item heading',
                            },
                            {
                                action => 'listed_group_item_text',
                                data   => '...',
                            }
                        ],
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><a class="list-group-item active" href="#"><h4 class="list-group-item-heading">List group item heading</h4><p class="list-group-item-text">...</p></a></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'listed_group',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListedGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        href   => '#',
                        active => 1,
                    }
                ],
            },           
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><a class="list-group-item active" href="#">Hello World</a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        data   => 'Hello World',
                        button => 1,
                    }
                ],
            },           
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><button class="list-group-item" type="button">Hello World</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group',
            expected => 'Moonshine::Element',
            args   => {
                list_items => [
                    {
                        active => 1,
                        href   => '#',
                        children  => [
                            {
                                action => 'listed_group_item_heading',
                                data   => 'List group item heading',
                            },
                            {
                                action => 'listed_group_item_text',
                                data   => '...',
                            }
                        ],
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="list-group"><a class="list-group-item active" href="#"><h4 class="list-group-item-heading">List group item heading</h4><p class="list-group-item-text">...</p></a></div>',
                }
            ],
        },
    ],
);

sunrise();
