use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::MediaLinkImage;
use Moonshine::Bootstrap::v3::MediaLinkImage;

moon_test(
    name => 'media_link_image',
    build => {
        class => 'Moonshine::Bootstrap::Component::MediaLinkImage',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'media_link_image',
            args   => {
                href => '#',
                img  => { src => 'url', alt => 'alt text' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<a href="#"><img alt="alt text" class="media-object" src="url"></img></a>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'media_link_image',
    build => {
        class => 'Moonshine::Bootstrap::v3::MediaLinkImage',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'media_link_image',
            args   => {
                href => '#',
                img  => { src => 'url', alt => 'alt text' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<a href="#"><img alt="alt text" class="media-object" src="url"></img></a>'
                }
            ],
        },
    ],
);

sunrise();
