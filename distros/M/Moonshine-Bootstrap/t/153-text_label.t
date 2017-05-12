use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::TextLabel;
use Moonshine::Bootstrap::v3::TextLabel;

moon_test(
    name  => 'text_label',
    build => {
        class => 'Moonshine::Bootstrap::Component::TextLabel',
    },
    instructions => [
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data => 'New',
            },
            subtest => [
                {
                    test     => 'render',
                    expected => '<span class="label label-default">New</span>'
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data   => 'Primary',
                switch => 'primary',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-primary">Primary</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Success',
                switch => 'success',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-success">Success</span>'
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data   => 'Warning',
                switch => 'warning',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-warning">Warning</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Info',
                switch => 'info',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<span class="label label-info">Info</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Danger',
                switch => 'danger',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<span class="label label-danger">Danger</span>'
                }
            ],
        }
    ],
);

moon_test(
    name  => 'text_label',
    build => {
        class => 'Moonshine::Bootstrap::v3::TextLabel',
    },
    instructions => [
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data => 'New',
            },
            subtest => [
                {
                    test     => 'render',
                    expected => '<span class="label label-default">New</span>'
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data   => 'Primary',
                switch => 'primary',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-primary">Primary</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Success',
                switch => 'success',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-success">Success</span>'
                }
            ],
        },
        {
            test     => 'obj',
            func     => 'text_label',
            expected => 'Moonshine::Element',
            args     => {
                data   => 'Warning',
                switch => 'warning',
            },
            subtest => [
                {
                    test => 'render',
                    expected =>
                      '<span class="label label-warning">Warning</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Info',
                switch => 'info',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<span class="label label-info">Info</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'text_label',
            args => {
                data   => 'Danger',
                switch => 'danger',
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<span class="label label-danger">Danger</span>'
                }
            ],
        }
    ],
);

sunrise();
