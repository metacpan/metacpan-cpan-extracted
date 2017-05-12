use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::DropdownUl;
use Moonshine::Bootstrap::v3::DropdownUl;

moon_test(
    name => 'dropdown_ul',
    build => {
        class => 'Moonshine::Bootstrap::Component::DropdownUl',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                alignment       => 'right',
                aria_labelledby => 'dropdownMenu1',
                children        => [
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                separators      => [2],
                aria_labelledby => 'dropdownMenu1',
                children        => [
                    {
                        action  => 'linked_li',
                        link    => 'http://some.url',
                        data    => 'URL',
                    },
                    {
                        action  => 'linked_li',
                        link    => 'http://second.url',
                        data    => 'Second',
                    }
                ],          
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li class="divider" role="separator"></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                separators      => [ 1, 3, 5 ],
                aria_labelledby => 'dropdownMenu1',
                children        => [
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li class="divider" role="separator"></li><li><a href="http://some.url">URL</a></li><li class="divider" role="separator"></li><li><a href="http://second.url">Second</a></li><li class="divider" role="separator"></li></ul>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'dropdown_ul',
    build => {
        class => 'Moonshine::Bootstrap::v3::DropdownUl',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                alignment       => 'right',
                aria_labelledby => 'dropdownMenu1',
                children        => [
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                separators      => [2],
                aria_labelledby => 'dropdownMenu1',
                children        => [
                    {
                        action  => 'linked_li',
                        link    => 'http://some.url',
                        data    => 'URL',
                    },
                    {
                        action  => 'linked_li',
                        link    => 'http://second.url',
                        data    => 'Second',
                    }
                ],          
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li><a href="http://some.url">URL</a></li><li class="divider" role="separator"></li><li><a href="http://second.url">Second</a></li></ul>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_ul',
            args => {
                separators      => [ 1, 3, 5 ],
                aria_labelledby => 'dropdownMenu1',
                children        => [
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
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="dropdown-menu" aria-labelledby="dropdownMenu1"><li class="divider" role="separator"></li><li><a href="http://some.url">URL</a></li><li class="divider" role="separator"></li><li><a href="http://second.url">Second</a></li><li class="divider" role="separator"></li></ul>'
                }
            ],
        },
    ],
);





sunrise();
