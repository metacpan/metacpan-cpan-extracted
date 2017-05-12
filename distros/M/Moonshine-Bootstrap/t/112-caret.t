use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Caret;
use Moonshine::Bootstrap::v3::Caret;

moon_test(
    name => 'caret',
    build => {
        class => 'Moonshine::Bootstrap::Component::Caret',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'caret',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<span class="caret"></span>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'caret v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Caret',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'caret',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<span class="caret"></span>',
                }
            ],
        },
    ],
);

sunrise();

1;
