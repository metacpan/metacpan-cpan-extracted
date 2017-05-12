use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::v3;

moon_test(
    name => 'children',
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
                children => [
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
                    expected => '<div class="well">...<div class="glyphicon glyphicon-search" aria-hidden="true"></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                children => [
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
                    expected => '<div class="well">...<div class="glyphicon glyphicon-search" aria-hidden="true"></div><div class="glyphicon glyphicon-trash" aria-hidden="true"></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                children => [
                    {
                        action        => 'glyphicon',
                        tag           => 'div',
                        switch        => 'search',
                        children => [
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
                    expected => '<div class="well">...<div class="glyphicon glyphicon-search" aria-hidden="true"><div class="glyphicon glyphicon-home" aria-hidden="true"></div></div><div class="glyphicon glyphicon-trash" aria-hidden="true"></div></div>'
                }
            ],
        },   
        {
            test => 'obj',
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                children => [
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
                    expected => '<div class="well">...<div class="glyphicon glyphicon-search" aria-hidden="true"></div></div>'
                }
            ],
        },
        {
            catch => 1,
            func => 'well',
            expected => 'Moonshine::Element',
            args   => {
                data          => '...',
                children => [
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
