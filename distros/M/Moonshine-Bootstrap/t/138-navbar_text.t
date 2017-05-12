use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarText;
use Moonshine::Bootstrap::v3::NavbarText;

moon_test(
    name => 'navbar_text',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarText',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_text',
            expected => 'Moonshine::Element',
            args => {
                data => 'Ping',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text">Ping</p>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'navbar_text v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarText',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_text',
            expected => 'Moonshine::Element',
            args => {
                data => 'one',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="navbar-text">one</p>',
                }
            ],
        },
    ],
);

sunrise();

1;
