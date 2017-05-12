use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Col;
use Moonshine::Bootstrap::v3::Col;

moon_test(
    name => 'col',
    build => {
        class => 'Moonshine::Bootstrap::Component::Col',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { xs => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-xs-6"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { sm => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-sm-6"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { xs => 6, md => 6, sm => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-md-6 col-sm-6 col-xs-6"></div>'
                }
            ],
        }
    ],
);

moon_test(
    name => 'col',
    build => {
        class => 'Moonshine::Bootstrap::v3::Col',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { xs => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-xs-6"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { sm => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-sm-6"></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'col',
            expected => 'Moonshine::Element',
            args     => { xs => 6, md => 6, sm => 6 },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="col-md-6 col-sm-6 col-xs-6"></div>'
                }
            ],
        }
    ],
);

sunrise();

1;
