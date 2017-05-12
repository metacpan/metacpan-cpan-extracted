use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::v3;

moon_test(
    name => 'caret',
    build => {
        class => 'Moonshine::Bootstrap::v3',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                after_element => [
                    {
                        action => 'glyphicon',
                        tag    => 'div',
                        switch => 'search',
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div><div class="glyphicon glyphicon-search" aria-hidden="true"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                after_element => [
                    {
                        action => 'glyphicon',
                        tag    => 'div',
                        switch => 'search',
                    },
                    {
                        action => 'glyphicon',
                        tag    => 'div',
                        switch => 'trash',
                    }
                ],           
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div><div class="glyphicon glyphicon-search" aria-hidden="true"></div><div class="glyphicon glyphicon-trash" aria-hidden="true"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                after_element => [
                    {
                        action        => 'glyphicon',
                        tag           => 'div',
                        switch        => 'search',
                        after_element => [
                            {
                                action => 'glyphicon',
                                tag    => 'div',
                                switch => 'home',
                            }
                        ]
                    },
                    {
                        action => 'glyphicon',
                        tag    => 'div',
                        switch => 'trash',
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div><div class="glyphicon glyphicon-search" aria-hidden="true"></div><div class="glyphicon glyphicon-home" aria-hidden="true"></div><div class="glyphicon glyphicon-trash" aria-hidden="true"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                after_element => [
                    {
                        tag         => 'div',
                        class       => 'glyphicon glyphicon-search',
                        aria_hidden => 'true',
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="well">...</div><div class="glyphicon glyphicon-search" aria-hidden="true"></div>'
                }
            ],
        },
        {
            catch => 1,
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                after_element => [
                    {
                        class       => 'glyphicon glyphicon-search',
                        aria_hidden => 'true',
                    }
                ],
            },
            expected => qr/no instructions to build the element:/,
        },
    ],
);

sunrise();
