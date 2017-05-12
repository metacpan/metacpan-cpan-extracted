use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarTextLink;
use Moonshine::Bootstrap::v3::NavbarTextLink;

moon_test(
    name => 'navbar_text_link',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarTextLink',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_text_link',
            expected => 'Moonshine::Element',
            args   => { 
                data => 'Navbar Text',
                link => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_text_link',
            expected => 'Moonshine::Element',
            args   => { 
                data      => 'Navbar Text',
                alignment => 'left',
                link      => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text navbar-left">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
                }
            ],
        },

    ]
);

moon_test(
    name => 'navbar_text_link - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarTextLink',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_text_link',
            expected => 'Moonshine::Element',
            args   => { 
                data => 'Navbar Text',
                link => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_text_link',
            expected => 'Moonshine::Element',
            args   => { 
                data      => 'Navbar Text',
                alignment => 'left',
                link      => {
                    href => "some.url",
                    data => "More Text",
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text navbar-left">Navbar Text<a class="navbar-link" href="some.url">More Text</a></p>'
                }
            ],
        },
    ]
);


sunrise();
