use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::EmbedResponsive;
use Moonshine::Bootstrap::v3::EmbedResponsive;

moon_test(
    name => 'embed_responsive',
    build => {
        class => 'Moonshine::Bootstrap::Component::EmbedResponsive',        
    },
    instructions => [
         {
            test => 'obj',
            func => 'embed_responsive',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'embed_responsive',
            expected => 'Moonshine::Element',
            args => {
                ratio => '16by9',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive embed-responsive-16by9"></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'embed_responsive',
    build => {
        class => 'Moonshine::Bootstrap::v3::EmbedResponsive',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'embed_responsive',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'embed_responsive',
            expected => 'Moonshine::Element',
            args => {
                ratio => '16by9',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive embed-responsive-16by9"></div>'
                }
            ],
        },
    ],
);

sunrise();

1;
