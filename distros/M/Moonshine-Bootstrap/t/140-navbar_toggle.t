use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarToggle;
use Moonshine::Bootstrap::v3::NavbarToggle;

moon_test(
    name => 'navbar_toggle',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarToggle',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_toggle',
            expected => 'Moonshine::Element',
            args   => { data_target => 'bs-example-navbar-collapse-1' },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button>',
                }
            ],
        },
    ]
);

moon_test(
    name => 'navbar_toggle',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarToggle',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_toggle',
            expected => 'Moonshine::Element',
            args   => { data_target => 'bs-example-navbar-collapse-1' },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="navbar-toggle collapsed" type="button" aria-expanded="false" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button>',
                }
            ],
        },
    ]
);

sunrise();
