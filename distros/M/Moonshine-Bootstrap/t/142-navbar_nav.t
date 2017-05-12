use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarNav;
use Moonshine::Bootstrap::v3::NavbarNav;

moon_test(
    name => 'nav',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarNav',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_nav',
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
                    expected => '<ul class="navbar-nav nav nav-tabs"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'nav',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarNav',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_nav',
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
                    expected => '<ul class="navbar-nav nav nav-tabs"><li class="active" role="presentation"><a href="#">Home</a></li><li role="presentation"><a href="#">Profile</a></li><li role="presentation"><a href="#">Messages</a></li></ul>',
                }
            ],
        },
    ],
);





sunrise();
