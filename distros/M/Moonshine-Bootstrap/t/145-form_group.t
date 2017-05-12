use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::FormGroup;
use Moonshine::Bootstrap::v3::FormGroup;

moon_test(
    name => 'form_group',
    build => {
        class => 'Moonshine::Bootstrap::Component::FormGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'form_group',
            args   => {
                fields => [
                    {
                        field_type  => 'text',
                        placeholder => 'Search'
                    },
                ]
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'form_group v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::FormGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'form_group',
            args   => {
                fields => [
                    {
                        field_type  => 'text',
                        placeholder => 'Search'
                    },
                ]
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div>'
                }
            ],
        },
    ],
);

sunrise();

1;
