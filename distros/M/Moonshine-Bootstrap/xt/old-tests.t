use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Bootstrap');
}

subtest "build" => sub {
    my $class = Moonshine::Bootstrap->new();

    component_test(
        {
            class  => $class,
            action => 'link_image',
            args   => {
                class => 'navbar-brand',
                img => {
                    alt => 'Brand',
                    src => 'some.src',
                },
                href => 'some.url',
            },
            expected =>
'<a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_header',
            args   => {
                headers => [
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
            expected =>
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_header',
            args   => {
                headers => [
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
            expected =>
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_header',
            args   => {
                headers => [
                    {
                        header_type => 'link_image',
                        img         => {
                            alt => 'Brand',
                            src => 'some.src',
                        },
                        href => 'some.url',
                    },
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
            expected =>
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div></div></nav>'
        }
    );


    component_test(
        {
            class  => $class,
            action => 'navbar_form',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'submit_button',
                    },
                ]
            },
            expected =>
'<form class="navbar-form navbar-left" role="search"><button class="btn btn-default" type="submit">Submit</button></form>'

        }
    );


    component_test(
        {
            class  => $class,
            action => 'navbar_form',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'field_group',
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
            expected =>
'<form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
                navs => [
                    {
                        alignment => 'left',
                        nav_type  => 'form',
                        role      => 'search',
                        fields    => [
                            {
                                field_type => 'field_group',
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
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
                navs => [
                    {
                        nav_type => 'button',
                    },
                ],
            },
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><button class="btn btn-default navbar-btn" type="button">Submit</button></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_button',
            args   => {
                data => 'Menu'
            },
            expected =>
'<button class="btn btn-default navbar-btn" type="button">Menu</button>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_button',
            args   => {
                alignment => 'right',
                data      => 'Menu'
            },
            expected =>
'<button class="btn btn-default navbar-btn navbar-right" type="button">Menu</button>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_text',
            args   => {
                data => 'Navbar Text',
            },
            expected => '<p class="navbar-text">Navbar Text</p>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
                navs => [
                    {
                        nav_type => 'text',
                        data     => 'Navbar Text',
                    },
                ],
            },
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text</p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_text_link',
            args   => {
                data => 'Navbar Text',
                link => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            expected =>
'<p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_text_link',
            args   => {
                data      => 'Navbar Text',
                alignment => 'left',
                link      => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            expected =>
'<p class="navbar-text navbar-left">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default navbar-fixed-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default navbar-fixed-bottom"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-inverse navbar-static-top"><div class="container-fluid"><p class="navbar-text navbar-right">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_toggle',
            args   => { data_target => 'bs-example-navbar-collapse-1' },
            expected =>
'<button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div></div></nav>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_brand',
            args   => {
                data => 'Brand',
                href => '#',
            },
            expected => '<a class="navbar-brand" href="#">Brand</a>'
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_collapse',
            args   => {
                id   => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'nav',
                        items    => [
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
            },
            expected =>
'<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1"><ul class="nav navbar-nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul></div>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar_collapse',
            args   => {
                id   => 'bs-example-navbar-collapse-1',
                navs => [
                    {
                        nav_type => 'nav',
                        items    => [
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
                                field_type => 'field_group',
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
                        items     => [
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
            },
            expected =>
'<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1"><ul class="nav navbar-nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form><ul class="nav navbar-nav navbar-right"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul></div>',
        }
    );

    component_test(
        {
            class  => $class,
            action => 'navbar',
            args   => {
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
                                items    => [
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
                                        field_type => 'field_group',
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
                                items     => [
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
                ],
            },
            expected =>
'<nav class="navbar navbar-default"><div class="container-fluid"><div class="navbar-header"><button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#">Brand</a></div><div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1"><ul class="nav navbar-nav"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul><form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form><ul class="nav navbar-nav navbar-right"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul></div></div></nav>',
        }
    );

};

sub component_test {
    my $args = shift;

    my $action = $args->{action};
    my $element = $args->{class}->$action( $args->{args} // {} );
    return is( $element->render, $args->{expected},
        "got expected $args->{expected}" );
}

done_testing();
