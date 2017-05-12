use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Breadcrumb;
use Moonshine::Bootstrap::v3::Breadcrumb;

moon_test(
    name => 'breadcrumb',
    build => {
        class => 'Moonshine::Bootstrap::Component::Breadcrumb',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'breadcrumb',
            args   => {
                crumbs => [
                    {
                        link => '#',
                        data => 'Home',
                    },
                    {
                        link => '#',
                        data => 'Library',
                    },
                    {
                        active => 1,
                        data   => 'Data',
                    }
                ],
            },

            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ol class="breadcrumb"><li><a href="#">Home</a></li><li><a href="#">Library</a></li><li class="active">Data</li></ol>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'breadcrumb',
    build => {
        class => 'Moonshine::Bootstrap::v3::Breadcrumb',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'breadcrumb',
            args   => {
                crumbs => [
                    {
                        link => '#',
                        data => 'Home',
                    },
                    {
                        link => '#',
                        data => 'Library',
                    },
                    {
                        active => 1,
                        data   => 'Data',
                    }
                ],
            },

            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<ol class="breadcrumb"><li><a href="#">Home</a></li><li><a href="#">Library</a></li><li class="active">Data</li></ol>'
                }
            ],
        },
    ],
);

sunrise();
