use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::PanelTitle;
use Moonshine::Bootstrap::v3::PanelTitle;

moon_test(
    name => 'panel_title',
    build => {
        class => 'Moonshine::Bootstrap::Component::PanelTitle',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_title',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<h3 class="panel-title"></h3>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel_title',
            expected => 'Moonshine::Element',
            args => {
                data => 'mehhh',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<h3 class="panel-title">mehhh</h3>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'panel_title',
    build => {
        class => 'Moonshine::Bootstrap::v3::PanelTitle',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_title',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<h3 class="panel-title"></h3>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel_title',
            expected => 'Moonshine::Element',
            args => {
                data => 'mehhh',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<h3 class="panel-title">mehhh</h3>',
                }
            ],
        },
    ],
);

sunrise();
