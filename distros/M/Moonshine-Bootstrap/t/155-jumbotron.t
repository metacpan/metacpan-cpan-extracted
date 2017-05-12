use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Jumbotron;
use Moonshine::Bootstrap::v3::Jumbotron;

moon_test(
    name => 'jumbotron',
    build => {
        class => 'Moonshine::Bootstrap::Component::Jumbotron',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'jumbotron',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'jumbotron',
            args   => { full_width => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"><div class="container"></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'jumbotron',
            args   => {
                children => [
                    {
                        action => 'h1',
                        data   => 'Hello, world!',
                    },
                    {
                        action => 'p',
                        data   => 'yoooo',
                    },
                    {
                        action => 'button',
                        tag    => 'a',
                        sizing => 'lg',
                        href   => '#',
                        role   => 'button',
                        data   => 'Learn more',
                        switch => 'primary'
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"><h1>Hello, world!</h1><p>yoooo</p><a class="btn btn-primary btn-lg" href="#" type="button" role="button">Learn more</a></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'jumbotron',
    build => {
        class => 'Moonshine::Bootstrap::v3::Jumbotron',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'jumbotron',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'jumbotron',
            args   => { full_width => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"><div class="container"></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'jumbotron',
            args   => {
                children => [
                    {
                        action => 'h1',
                        data   => 'Hello, world!',
                    },
                    {
                        action => 'p',
                        data   => 'yoooo',
                    },
                    {
                        action => 'button',
                        tag    => 'a',
                        sizing => 'lg',
                        href   => '#',
                        role   => 'button',
                        data   => 'Learn more',
                        switch => 'primary'
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="jumbotron"><h1>Hello, world!</h1><p>yoooo</p><a class="btn btn-primary btn-lg" href="#" type="button" role="button">Learn more</a></div>',
                }
            ],
        },
    ],
);



sunrise();
