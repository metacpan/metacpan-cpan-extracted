use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Thumbnail;
use Moonshine::Bootstrap::v3::Thumbnail;

moon_test(
    name => 'thumbnail',
    build => {
        class => 'Moonshine::Bootstrap::Component::Thumbnail',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'thumbnail',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="thumbnail"></div>',
                }
            ],
        },
    ],
);


moon_test(
    name => 'thumbnail',
    build => {
        class => 'Moonshine::Bootstrap::v3::Thumbnail',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'thumbnail',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="thumbnail"></div>',
                }
            ],
        },
    ],
);

sunrise();
