use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::PanelFooter;
use Moonshine::Bootstrap::v3::PanelFooter;

moon_test(
    name => 'panel_footer',
    build => {
        class => 'Moonshine::Bootstrap::Component::PanelFooter',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_footer',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-footer">Basic panel example</div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'panel_footer',
    build => {
        class => 'Moonshine::Bootstrap::v3::PanelFooter',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel_footer',
            expected => 'Moonshine::Element',
            args   => {
                data => 'Basic panel example',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel-footer">Basic panel example</div>'
                }
            ],
        },
    ],
);

sunrise();
