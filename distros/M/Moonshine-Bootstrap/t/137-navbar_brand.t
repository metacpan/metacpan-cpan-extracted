use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarBrand;
use Moonshine::Bootstrap::v3::NavbarBrand;

moon_test(
    name => 'navbar_brand',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarBrand',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_brand',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="navbar-brand" href="#"></a>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'navbar_brand v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarBrand',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_brand',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="navbar-brand" href="#"></a>',
                }
            ],
        },
    ],
);

sunrise();

1;
