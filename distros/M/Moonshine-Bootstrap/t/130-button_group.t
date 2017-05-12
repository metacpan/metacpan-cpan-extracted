use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ButtonGroup;
use Moonshine::Bootstrap::v3::ButtonGroup;

moon_test(
    name => 'button group',
    build => {
        class => 'Moonshine::Bootstrap::Component::ButtonGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                vertical => 1,
                group    => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-vertical" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                justified => 1,
                group     => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-justified" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
                nested => [
                    {
                        index => 3,
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
               group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                    {
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
                nested => [
                    {
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                sizing => 'lg',
                group  => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-lg" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
    ],
);


moon_test(
    name => 'button_group - v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::ButtonGroup',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                vertical => 1,
                group    => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-vertical" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                justified => 1,
                group     => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-justified" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
                nested => [
                    {
                        index => 3,
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
               group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                    {
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                group => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
                nested => [
                    {
                        group => [
                            {
                                data => 'one',
                            },
                            {
                                data => 'two',
                            },
                        ],
                    }
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button><div class="btn-group" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div></div>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'button_group',
            args => {
                sizing => 'lg',
                group  => [
                    {
                        data => 'one',
                    },
                    {
                        data => 'two',
                    },
                ],
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="btn-group btn-group-lg" role="group"><button class="btn btn-default" type="button">one</button><button class="btn btn-default" type="button">two</button></div>'
                }
            ],
        },
    ],
);

sunrise();
