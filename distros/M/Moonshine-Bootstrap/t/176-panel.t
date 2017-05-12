use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Panel;
use Moonshine::Bootstrap::v3::Panel;

moon_test(
    name => 'panel',
    build => {
        class => 'Moonshine::Bootstrap::Component::Panel',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                body => {
                    data => 'Basic panel example',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-body">Basic panel example</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
               header => {
                    data => 'Basic panel example',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-heading">Basic panel example</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                header => {
                    data => 'Basic panel example',
                },
                body => {
                    data => '...'
                }           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-heading">Basic panel example</div><div class="panel-body">...</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'success',
                header => {
                    data => 'Basic panel example',
                },
                body => {
                    data => '...'
                }           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-success"><div class="panel-heading">Basic panel example</div><div class="panel-body">...</div></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'panel v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Panel',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                body => {
                    data => 'Basic panel example',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-body">Basic panel example</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
               header => {
                    data => 'Basic panel example',
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-heading">Basic panel example</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                header => {
                    data => 'Basic panel example',
                },
                body => {
                    data => '...'
                }           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-default"><div class="panel-heading">Basic panel example</div><div class="panel-body">...</div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'panel',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'success',
                header => {
                    data => 'Basic panel example',
                },
                body => {
                    data => '...'
                }           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="panel panel-success"><div class="panel-heading">Basic panel example</div><div class="panel-body">...</div></div>'
                }
            ],
        },
    ],
);

sunrise();
