use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Nav;
use Moonshine::Bootstrap::v3::Nav;

moon_test(
    name => 'nav',
    build => {
        class => 'Moonshine::Bootstrap::Component::Nav',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch  => 'tabs',
                nav_items => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-tabs"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch  => 'pills',
                nav_items => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                stacked => 1,
                nav_items   => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-stacked"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],           
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data    => 'Profile',
                        disable => 1,
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li class="disabled" role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data    => 'Profile',
                        disable => 1,
                    },
                    {
                        data     => 'Messages',
                        dropdown => {
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
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li class="disabled" role="presentation"><a href="#">Profile</a></li><li role="presentation"><a class="dropdown-toggle" href="#" aria-expanded="false" aria-haspopup="true" role="button" data-toggle="dropdown">Messages</a><ul class="dropdown-menu"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></li></ul>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'nav',
    build => {
        class => 'Moonshine::Bootstrap::v3::Nav',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch  => 'tabs',
                nav_items => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-tabs"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch  => 'pills',
                nav_items => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                stacked => 1,
                nav_items   => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-stacked"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data => 'Profile',
                    },
                    {
                        data => 'Messages',
                    }
                ],           
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data    => 'Profile',
                        disable => 1,
                    },
                    {
                        data => 'Messages',
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li class="disabled" role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'nav',
            args   => {
                switch    => 'pills',
                justified => 1,
                nav_items     => [
                    {
                        data   => 'Home',
                        active => 1,
                    },
                    {
                        data    => 'Profile',
                        disable => 1,
                    },
                    {
                        data     => 'Messages',
                        dropdown => {
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
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ul class="nav nav-pills nav-justified"><li class="active" role="presentation"><a href="#">Home</a></li><li class="disabled" role="presentation"><a href="#">Profile</a></li><li role="presentation"><a class="dropdown-toggle" href="#" aria-expanded="false" aria-haspopup="true" role="button" data-toggle="dropdown">Messages</a><ul class="dropdown-menu"><li><a href="http://some.url">URL</a></li><li><a href="http://second.url">Second</a></li></ul></li></ul>'
                }
            ],
        },
    ],
);





sunrise();
