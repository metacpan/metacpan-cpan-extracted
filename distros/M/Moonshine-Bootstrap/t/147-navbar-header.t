use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarHeader;
use Moonshine::Bootstrap::v3::NavbarHeader;

moon_test(
    name => 'navbar_header',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
            subtest => [
                {
                    test => 'render',
                    expected => 
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
                ]           
            },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        }
    ],
);

moon_test(
    name => 'navbar_header',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
            subtest => [
                {
                    test => 'render',
                    expected => 
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_header',
            expected => 'Moonshine::Element',
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
                ]           
            },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<div class="navbar-header"><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a><a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a></div>'
                }
            ],
        }
    ],
);



sunrise();
