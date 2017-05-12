use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ButtonToolbar;
use Moonshine::Bootstrap::v3::ButtonToolbar;

moon_test(
    name => 'button_toolbar',
    build => {
        class => 'Moonshine::Bootstrap::Component::ButtonToolbar',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button_toolbar',
            args   => {
                toolbar => [
                    {
                        group => [
                            {
                                data => 'one',
                            },
                        ],
                    },
                    {
                        group => [
                            {
                                data => 'two',
                            }
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected =>'<div class="btn-toolbar" role="toolbar"><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button></div><div class="btn-group" role="group"><button class="btn btn-default" type="button">two</button></div></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'button_toolbar',
    build => {
        class => 'Moonshine::Bootstrap::v3::ButtonToolbar',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button_toolbar',
            args   => {
                toolbar => [
                    {
                        group => [
                            {
                                data => 'one',
                            },
                        ],
                    },
                    {
                        group => [
                            {
                                data => 'two',
                            }
                        ],
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected =>'<div class="btn-toolbar" role="toolbar"><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button></div><div class="btn-group" role="group"><button class="btn btn-default" type="button">two</button></div></div>',
                }
            ],
        },
    ],
);



sunrise();
