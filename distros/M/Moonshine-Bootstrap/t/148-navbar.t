use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Navbar;
use Moonshine::Bootstrap::v3::Navbar;

moon_test(
    name  => 'navbar',
    build => {
        class => 'Moonshine::Bootstrap::Component::Navbar',
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'link_image',
                                img         => {
                                    alt => 'Brand',
                                    src => 'some.src',
                                },
                                href => 'some.url',
                            },
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div></div></nav>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        alignment => 'left',
                        nav_type  => 'form',
                        role      => 'search',
                        fields    => [
                            {
                                field_type => 'form_group',
                                fields     => [
                                    {
                                        field_type  => 'text',
                                        placeholder => 'Search'
                                    },
                                ],
                            },
                            {
                                field_type => 'submit_button',
                            }
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'button',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><button class="navbar-btn btn btn-default" type="button">Submit</button></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'text',
                        data     => 'Navbar Text',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text</p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'text_link',
                        data     => 'Navbar Text',
                        link     => {
                            href => 'some.url',
                            data => 'More Text',
                        }
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        }
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                fixed => 'top',
                navs  => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-fixed-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                fixed => 'bottom',
                navs  => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-fixed-bottom"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                static => 'top',
                switch => 'inverse',
                navs   => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-inverse navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                static => 'top',
                navs   => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                mid  => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'toggle',
                            },
                            {
                                header_type => 'brand',
                                data        => 'Brand',
                                href        => '#',
                            }
                        ],
                    }
                ]
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                mid  => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'toggle',
                            },
                            {
                                header_type => 'brand',
                                data        => 'Brand',
                                href        => '#',
                            }
                        ],
                    },
                    {
                        nav_type => 'collapse',
                        navs     => [
                            {
                                nav_type => 'nav',
                                nav_items    => [
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
                            {
                                alignment => 'left',
                                nav_type  => 'form',
                                role      => 'search',
                                fields    => [
                                    {
                                        field_type => 'form_group',
                                        fields     => [
                                            {
                                                field_type  => 'text',
                                                placeholder => 'Search'
                                            },
                                        ],
                                    },
                                    {
                                        field_type => 'submit_button',
                                    }
                                ],
                            },
                            {
                                nav_type  => 'nav',
                                alignment => 'right',
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
                        ],
                    }
                ]
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div><div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1"><ul class="navbar-nav nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form><ul class="navbar-nav navbar-right nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul></div></div></nav>',
                }
            ],
        },

    ],
);

moon_test(
    name  => 'navbar',
    build => {
        class => 'Moonshine::Bootstrap::v3::Navbar',
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'link_image',
                                img         => {
                                    alt => 'Brand',
                                    src => 'some.src',
                                },
                                href => 'some.url',
                            },
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div></div></nav>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        alignment => 'left',
                        nav_type  => 'form',
                        role      => 'search',
                        fields    => [
                            {
                                field_type => 'form_group',
                                fields     => [
                                    {
                                        field_type  => 'text',
                                        placeholder => 'Search'
                                    },
                                ],
                            },
                            {
                                field_type => 'submit_button',
                            }
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'button',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><button class="navbar-btn btn btn-default" type="button">Submit</button></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'text',
                        data     => 'Navbar Text',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text</p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type => 'text_link',
                        data     => 'Navbar Text',
                        link     => {
                            href => 'some.url',
                            data => 'More Text',
                        }
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                navs => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        }
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                fixed => 'top',
                navs  => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-fixed-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                fixed => 'bottom',
                navs  => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-fixed-bottom"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                static => 'top',
                switch => 'inverse',
                navs   => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-inverse navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                static => 'top',
                navs   => [
                    {
                        nav_type  => 'text_link',
                        data      => 'Navbar Text',
                        alignment => 'right',
                        link      => {
                            href => 'some.url',
                            data => 'More Text',
                        },
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                mid  => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'toggle',
                            },
                            {
                                header_type => 'brand',
                                data        => 'Brand',
                                href        => '#',
                            }
                        ],
                    }
                ]
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div></div></nav>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar',
            args => {
                mid  => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'header',
                        headers  => [
                            {
                                header_type => 'toggle',
                            },
                            {
                                header_type => 'brand',
                                data        => 'Brand',
                                href        => '#',
                            }
                        ],
                    },
                    {
                        nav_type => 'collapse',
                        navs     => [
                            {
                                nav_type => 'nav',
                                nav_items    => [
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
                            {
                                alignment => 'left',
                                nav_type  => 'form',
                                role      => 'search',
                                fields    => [
                                    {
                                        field_type => 'form_group',
                                        fields     => [
                                            {
                                                field_type  => 'text',
                                                placeholder => 'Search'
                                            },
                                        ],
                                    },
                                    {
                                        field_type => 'submit_button',
                                    }
                                ],
                            },
                            {
                                nav_type  => 'nav',
                                alignment => 'right',
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
                        ],
                    }
                ]
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div><div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1"><ul class="navbar-nav nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form><ul class="navbar-nav navbar-right nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul></div></div></nav>',
                }
            ],
        },

    ],
);

sunrise();
