use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Alert;
use Moonshine::Bootstrap::v3::Alert;

moon_test(
    name => 'alert',
    build => {
        class => 'Moonshine::Bootstrap::Component::Alert',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Primary',
                switch => 'primary',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-primary">Primary</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Success',
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-success">Success</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            args   => {
                data   => 'Warning',
                switch => 'warning',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-warning">Warning</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Info',
                switch => 'info',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-info">Info</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Danger',
                switch => 'danger',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-danger">Danger</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                link   => { data => 'Danger', href => '#' },
                switch => 'danger',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-danger"><a class="alert-link" href="#">Danger</a></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'alert',
    build => {
        class => 'Moonshine::Bootstrap::v3::Alert',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Primary',
                switch => 'primary',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-primary">Primary</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Success',
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-success">Success</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            args   => {
                data   => 'Warning',
                switch => 'warning',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-warning">Warning</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Info',
                switch => 'info',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-info">Info</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                data   => 'Danger',
                switch => 'danger',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-danger">Danger</div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'alert',
            expected => 'Moonshine::Element',
            args   => {
                link   => { data => 'Danger', href => '#' },
                switch => 'danger',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="alert alert-danger"><a class="alert-link" href="#">Danger</a></div>'
                }
            ],
        },
    ],
);

sunrise();
