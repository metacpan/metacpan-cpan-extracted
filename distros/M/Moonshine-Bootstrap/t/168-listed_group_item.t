use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListedGroupItem;
use Moonshine::Bootstrap::v3::ListedGroupItem;

moon_test(
    name => 'listed_group_item',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListedGroupItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Hello World',
                href => '#',
            }, 
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                href   => '#',
                active => 1,
            },  
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item active" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data    => 'Hello World',
                href    => '#',
                disable => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item disabled" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                href   => '#',
                badge  => { data => '41' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item active" href="#">Hello World<span class="badge">41</span></a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                button => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="list-group-item" type="button">Hello World</button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                button => 1,
                switch => 'success',           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="list-group-item list-group-item-success" type="button">Hello World</button>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'listed_group_item',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListedGroupItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Hello World',
                href => '#',
            }, 
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                href   => '#',
                active => 1,
            },  
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item active" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data    => 'Hello World',
                href    => '#',
                disable => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item disabled" href="#">Hello World</a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                href   => '#',
                badge  => { data => '41' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="list-group-item active" href="#">Hello World<span class="badge">41</span></a>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                button => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="list-group-item" type="button">Hello World</button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'listed_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                button => 1,
                switch => 'success',           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="list-group-item list-group-item-success" type="button">Hello World</button>'
                }
            ],
        },
    ],
);


sunrise();
