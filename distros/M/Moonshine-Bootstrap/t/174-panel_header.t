use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::PanelHeader;
use Moonshine::Bootstrap::v3::PanelHeader;

moon_test(
    name => 'panel_header',
    build => {
        class => 'Moonshine::Bootstrap::Component::PanelHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_header',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-heading">Basic panel example</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel_header',
            expected => 'Moonshine::Element',
            args   => {
                title => { data => 'Basic panel example' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-heading"><h3 class="panel-title">Basic panel example</h3></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'panel_header',
    build => {
        class => 'Moonshine::Bootstrap::v3::PanelHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_header',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-heading">Basic panel example</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel_header',
            expected => 'Moonshine::Element',
            args   => {
                title => { data => 'Basic panel example' },
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-heading"><h3 class="panel-title">Basic panel example</h3></div>'
                }
            ],
        },
    ],
);

sunrise();
