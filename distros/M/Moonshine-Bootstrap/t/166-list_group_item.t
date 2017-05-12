use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ListGroupItem;
use Moonshine::Bootstrap::v3::ListGroupItem;

moon_test(
    name => 'list_group_item',
    build => {
        class => 'Moonshine::Bootstrap::Component::ListGroupItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'list_group_item',
            args   => {
                data => 'Hello World',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
            },
            subtest => [
                {
                   test => 'render',
                   expected => '<li class="list-group-item active">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data    => 'Hello World',
                disable => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item disabled">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                badge  => { data => '41' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item active">Hello World<span class="badge">41</span></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                badge  => { data => '41' },
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item list-group-item-success active">Hello World<span class="badge">41</span></li>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'list_group_item',
    build => {
        class => 'Moonshine::Bootstrap::v3::ListGroupItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'list_group_item',
            args   => {
                data => 'Hello World',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
            },
            subtest => [
                {
                   test => 'render',
                   expected => '<li class="list-group-item active">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data    => 'Hello World',
                disable => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item disabled">Hello World</li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                badge  => { data => '41' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item active">Hello World<span class="badge">41</span></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'list_group_item',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Hello World',
                active => 1,
                badge  => { data => '41' },
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="list-group-item list-group-item-success active">Hello World<span class="badge">41</span></li>'
                }
            ],
        },
    ],
);



sunrise();
