use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavItem;
use Moonshine::Bootstrap::v3::NavItem;

moon_test(
    name => 'nav_item',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'nav_item',
            args   => {
                link => 'http://some.url',
                data => 'URL',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li role="presentation"><a href="http://some.url">URL</a></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav_item',
            args   => {
                link    => 'http://some.url',
                data    => 'URL',
                disable => 1,
                dropdown => {
                    aria_labelledby => 'dropdownMenu1',
                    children => [
                        {
                            action => 'linked_li',
                            link => 'http://some.url',
                            data => 'URL',
                        },
                        {
                            action => 'linked_li',
                            link => 'http://second.url',
                            data => 'Second',
                        }
                    ],
                },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="disabled" role="presentation"><a class="dropdown-toggle" href="http://some.url" aria-expanded="false" aria-haspopup="true" role="button" data-toggle="dropdown">URL</a><ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></li>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'nav_item',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavItem',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'nav_item',
            args   => {
                link => 'http://some.url',
                data => 'URL',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li role="presentation"><a href="http://some.url">URL</a></li>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav_item',
            args   => {
                link    => 'http://some.url',
                data    => 'URL',
                disable => 1,
                dropdown => {
                    aria_labelledby => 'dropdownMenu1',
                    children => [
                        {
                            action => 'linked_li',
                            link => 'http://some.url',
                            data => 'URL',
                        },
                        {
                            action => 'linked_li',
                            link => 'http://second.url',
                            data => 'Second',
                        }
                    ],
                },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="disabled" role="presentation"><a class="dropdown-toggle" href="http://some.url" aria-expanded="false" aria-haspopup="true" role="button" data-toggle="dropdown">URL</a><ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></li>',
                }
            ],
        },
    ],
);




sunrise();

1;
