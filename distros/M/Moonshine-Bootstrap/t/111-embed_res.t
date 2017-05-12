use Moonshine::Test qw/:all/;
use strict;
use warnings;
use Moonshine::Bootstrap::Component::EmbedRes;
use Moonshine::Bootstrap::v3::EmbedRes;

moon_test(
    name => 'Bootstrap - embed_res',
    build => {
        class => 'Moonshine::Bootstrap::Component::EmbedRes',        
    },
    instructions => [
         {
            test => 'obj',
            func => 'embed_res',
            args => {
                iframe => {
                    src => 'http://lnation.org',
                },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive"><iframe class="embed-responsive-item" src="http://lnation.org"></iframe></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'Bootstrap - embed_res - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::EmbedRes',        
    },
    instructions => [
         {
            test => 'obj',
            func => 'embed_res',
            args => {
                iframe => {
                    src => 'http://lnation.org',
                },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="embed-responsive"><iframe class="embed-responsive-item" src="http://lnation.org"></iframe></div>'
                }
            ],
        },
    ],
);

sunrise();

1;
