use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::LinkedLi;
use Moonshine::Bootstrap::v3::LinkedLi;

moon_test(
    name => 'linked_li',
    build => {
        class => 'Moonshine::Bootstrap::Component::LinkedLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'linked_li',
            args   => {
                link => 'http://some.url',
                data => 'URL',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li><a href="http://some.url">URL</a></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'linked_li',
            args   => {
                link    => 'http://some.url',
                data    => 'URL',
                disable => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="disabled"><a href="http://some.url">URL</a></li>'
                }
            ],
        },
    ],
);


moon_test(
    name => 'linked_li v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::LinkedLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'linked_li',
            args   => {
                link => 'http://some.url',
                data => 'URL',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li><a href="http://some.url">URL</a></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'linked_li',
            args   => {
                link    => 'http://some.url',
                data    => 'URL',
                disable => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="disabled"><a href="http://some.url">URL</a></li>'
                }
            ],
        },
    ],
);

sunrise();

1;
