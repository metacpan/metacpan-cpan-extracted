use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::LinkImage;
use Moonshine::Bootstrap::v3::LinkImage;

moon_test(
    name => 'link_image',
    build => {
        class => 'Moonshine::Bootstrap::Component::LinkImage',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'link_image',
            expected => 'Moonshine::Element',
            args   => {
                class => 'navbar-brand',
                img => {
                    alt => 'Brand',
                    src => 'some.src',
                },
                href => 'some.url',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'link_image',
    build => {
        class => 'Moonshine::Bootstrap::v3::LinkImage',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'link_image',
            expected => 'Moonshine::Element',
            args   => {
                class => 'navbar-brand',
                img => {
                    alt => 'Brand',
                    src => 'some.src',
                },
                href => 'some.url',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<a class="navbar-brand" href="some.url"><img alt="Brand" src="some.src"></img></a>'
                }
            ],
        },
    ],
);


sunrise();

1;
