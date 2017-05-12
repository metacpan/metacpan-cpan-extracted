use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Abbr;
use Moonshine::Bootstrap::v3::Abbr;

moon_test(
    name => 'abbr',
    build => {
        class => 'Moonshine::Bootstrap::Component::Abbr',        
    },
    instructions => [
       {
            test => 'obj',
            func => 'abbr',
            args => {
                title => 'HyperText Markup Language',
                data  => 'HTML'
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<abbr title="HyperText Markup Language">HTML</abbr>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'abbr',
            args => {
                title => 'HyperText Markup Language',
                data  => 'HTML',
                initialism => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<abbr class="initialism" title="HyperText Markup Language">HTML</abbr>',
                }
            ],
        },
     
    ],
);

moon_test(
    name => 'abbr - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::Abbr',        
    },
    instructions => [
       {
            test => 'obj',
            func => 'abbr',
            args => {
                title => 'HyperText Markup Language',
                data  => 'HTML'
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<abbr title="HyperText Markup Language">HTML</abbr>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'abbr',
            args => {
                title => 'HyperText Markup Language',
                data  => 'HTML',
                initialism => 1,
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<abbr class="initialism" title="HyperText Markup Language">HTML</abbr>',
                }
            ],
        },
     
    ],
);

sunrise();

1;
