use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Clearfix;
use Moonshine::Bootstrap::v3::Clearfix;

moon_test(
    name => 'clearfix',
    build => {
        class => 'Moonshine::Bootstrap::Component::Clearfix',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'clearfix',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="clearfix visible-xs-block"></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'clearfix v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Clearfix',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'clearfix',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="clearfix visible-xs-block"></div>',
                }
            ],
        },
    ],
);



sunrise();

1;
