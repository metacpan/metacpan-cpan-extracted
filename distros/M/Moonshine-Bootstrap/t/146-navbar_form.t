use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::NavbarForm;
use Moonshine::Bootstrap::v3::NavbarForm;

moon_test(
    name => 'navbar_form',
    build => {
        class => 'Moonshine::Bootstrap::Component::NavbarForm',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_form',
            expected => 'Moonshine::Element',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'submit_button',
                    },
                ]
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<form class="navbar-form navbar-left" role="search"><button class="btn btn-default" type="submit">Submit</button></form>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_form',
            expected => 'Moonshine::Element',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'form_group',
                        fields     => [
                            {
                                field_type  => 'text',
                                placeholder => 'Search'
                            },
                        ],
                    },
                    {
                        field_type => 'submit_button',
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'navbar_form',
    build => {
        class => 'Moonshine::Bootstrap::v3::NavbarForm',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'navbar_form',
            expected => 'Moonshine::Element',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'submit_button',
                    },
                ]
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<form class="navbar-form navbar-left" role="search"><button class="btn btn-default" type="submit">Submit</button></form>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'navbar_form',
            expected => 'Moonshine::Element',
            args   => {
                alignment => 'left',
                role      => 'search',
                fields    => [
                    {
                        field_type => 'form_group',
                        fields     => [
                            {
                                field_type  => 'text',
                                placeholder => 'Search'
                            },
                        ],
                    },
                    {
                        field_type => 'submit_button',
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<form class="navbar-form navbar-left" role="search"><div class="form-group"><input class="form-control" placeholder="Search" type="text"></input></div><button class="btn btn-default" type="submit">Submit</button></form>',
                }
            ],
        },
    ],
);

sunrise();
