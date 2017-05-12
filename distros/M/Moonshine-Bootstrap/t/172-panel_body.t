use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::PanelBody;
use Moonshine::Bootstrap::v3::PanelBody;

moon_test(
    name => 'panel_body',
    build => {
        class => 'Moonshine::Bootstrap::Component::PanelBody',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_body',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-body">Basic panel example</div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'panel_body',
    build => {
        class => 'Moonshine::Bootstrap::v3::PanelBody',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_body',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-body">Basic panel example</div>'
                }
            ],
        },
    ],
);

sunrise();
