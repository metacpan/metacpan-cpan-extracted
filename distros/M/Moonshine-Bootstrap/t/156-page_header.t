use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::PageHeader;
use Moonshine::Bootstrap::v3::PageHeader;

moon_test(
    name => 'page_header',
    build => {
        class => 'Moonshine::Bootstrap::Component::PageHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'page_header',
            expected => 'Moonshine::Element',
            args   => {
                header => {
                    data => 'Example page header'
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="page-header"><h1>Example page header</h1></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'page_header',
            args   => {
                header => {
                    data => 'Example page header ',
                },
                small => { data => 'Subtext for header' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="page-header"><h1>Example page header <small>Subtext for header</small></h1></div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'page_header',
    build => {
        class => 'Moonshine::Bootstrap::v3::PageHeader',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'page_header',
            expected => 'Moonshine::Element',
            args   => {
                header => {
                    data => 'Example page header'
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="page-header"><h1>Example page header</h1></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'page_header',
            args   => {
                header => {
                    data => 'Example page header ',
                },
                small =>  { data => 'Subtext for header' },
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="page-header"><h1>Example page header <small>Subtext for header</small></h1></div>',
                }
            ],
        },
    ],
);

sunrise();
