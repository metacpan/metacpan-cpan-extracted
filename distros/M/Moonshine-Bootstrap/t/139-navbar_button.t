use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarButton;
use Moonshine::Bootstrap::v3::NavbarButton;

moon_test(
    name => 'navbar_button',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarButton',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_button',
            expected => 'Moonshine::Element',
            args => {
                data => 'Menu'
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-btn btn btn-default" type="button">Menu</button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_button',
            expected => 'Moonshine::Element',
            args => {
                alignment => 'right',
                data      => 'Menu'
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-btn btn btn-default navbar-right" type="button">Menu</button>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'navbar_button',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarButton',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_button',
            expected => 'Moonshine::Element',
            args => {
                data => 'Menu'
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-btn btn btn-default" type="button">Menu</button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_button',
            expected => 'Moonshine::Element',
            args => {
                alignment => 'right',
                data      => 'Menu'
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-btn btn btn-default navbar-right" type="button">Menu</button>'
                }
            ],
        },
    ],
);


sunrise();
