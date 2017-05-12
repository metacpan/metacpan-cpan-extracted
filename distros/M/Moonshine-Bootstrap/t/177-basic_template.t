use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::BasicTemplate;
use Moonshine::Bootstrap::v3::BasicTemplate;

moon_test(
    name => 'basic_template',
    build => {
        class => 'Moonshine::Bootstrap::Component::BasicTemplate',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'basic_template',
            expected => 'Moonshine::Element',
            args => {},
            subtest => [
                {
                    test => 'render',
                    expected => '<html lang="en"><head><meta charset="utf-8"></meta><meta content="IE=edge" http-equiv="X-UA-Compatible"></meta><meta content="width=device-width, inline-scale=1" name="viewport"></meta></head><body></body></html>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'basic_template',
            expected => 'Moonshine::Element',
            args => {
                header => [
                    {
                        action      => 'title',
                        data        => 'Bootstrap 101 Template',
                    },
                    {
                        action      => 'link',
                        href        => 'css/bootstrap.min.css',
                        rel         => 'stylesheet',
                    }
                ],    
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<html lang="en"><head><meta charset="utf-8"></meta><meta content="IE=edge" http-equiv="X-UA-Compatible"></meta><meta content="width=device-width, inline-scale=1" name="viewport"></meta><title>Bootstrap 101 Template</title><link href="css/bootstrap.min.css" rel="stylesheet"></link></head><body></body></html>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'basic_template v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::BasicTemplate',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'basic_template',
            expected => 'Moonshine::Element',
            args => {},
            subtest => [
                {
                    test => 'render',
                    expected => '<html lang="en"><head><meta charset="utf-8"></meta><meta content="IE=edge" http-equiv="X-UA-Compatible"></meta><meta content="width=device-width, inline-scale=1" name="viewport"></meta></head><body></body></html>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'basic_template',
            expected => 'Moonshine::Element',
            args => {
                header => [
                    {
                        action      => 'title',
                        data        => 'Bootstrap 101 Template',
                    },
                    {
                        action      => 'link',
                        href        => 'css/bootstrap.min.css',
                        rel         => 'stylesheet',
                    }
                ],    
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<html lang="en"><head><meta charset="utf-8"></meta><meta content="IE=edge" http-equiv="X-UA-Compatible"></meta><meta content="width=device-width, inline-scale=1" name="viewport"></meta><title>Bootstrap 101 Template</title><link href="css/bootstrap.min.css" rel="stylesheet"></link></head><body></body></html>',
                }
            ],
        },
    ],
);

sunrise();


1;
