use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::SeparatorLi;
use Moonshine::Bootstrap::v3::SeparatorLi;

moon_test(
    name => 'separator_li',
    build => {
        class => 'Moonshine::Bootstrap::Component::SeparatorLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'separator_li',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="divider" role="separator"></li>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'separator_li v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::SeparatorLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'separator_li',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="divider" role="separator"></li>',
                }
            ],
        },
    ],
);

sunrise();

1;
