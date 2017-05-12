use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::EmbedResponsiveIframe;
use Moonshine::Bootstrap::v3::EmbedResponsiveIframe;

moon_test(
    name => 'embed_responsive_iframe',
    build => {
        class => 'Moonshine::Bootstrap::Component::EmbedResponsiveIframe',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'embed_responsive_iframe',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<iframe class="embed-responsive-item"></iframe>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'embed_responsive_iframe',
    build => {
        class => 'Moonshine::Bootstrap::v3::EmbedResponsiveIframe',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'embed_responsive_iframe',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<iframe class="embed-responsive-item"></iframe>'
                },
            ],
        },
    ],
);

sunrise();

1;
