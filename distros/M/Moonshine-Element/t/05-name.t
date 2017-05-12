#! perl
use Moonshine::Test qw/:all/;

use Moonshine::Element;

my $cite =
  Moonshine::Element->new( { tag => 'code', data => '&lt;section&gt;' } );

moon_test(
    name  => 'chain name',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag      => 'div',
            name     => 'one',
            children => [
                {
                    tag      => 'div',
                    name     => 'two',
                    children => [
                        {
                            tag  => 'div',
                            name => 'three',
                        }
                    ]
                }
            ]
        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div name="one"><div name="two"><div name="three"></div></div></div>',
        },
        {
            test     => 'obj',
            func     => 'two',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<div name="two"><div name="three"></div></div>',
                },
                {
                    test     => 'obj',
                    func     => 'three',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test     => 'render',
                            expected => '<div name="three"></div>',
                        }
                    ]
                }
            ]
        },
        {
            test     => 'obj',
            func     => 'three',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<div name="three"></div>',
                }
            ]
        }
    ],
);

moon_test(
    name  => 'chain name',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag            => 'div',
            name           => 'one',
            before_element => [
                {
                    tag      => 'div',
                    name     => 'two',
                    children => [
                        {
                            tag  => 'div',
                            name => 'three',
                        }
                    ]
                }
            ]
        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div name="two"><div name="three"></div></div><div name="one"></div>',
        },
        {
            test     => 'obj',
            func     => 'two',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<div name="two"><div name="three"></div></div>',
                },
                {
                    test     => 'obj',
                    func     => 'three',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test     => 'render',
                            expected => '<div name="three"></div>',
                        }
                    ]
                }
            ]
        },
        {
            test     => 'obj',
            func     => 'three',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<div name="three"></div>',
                }
            ]
        }
    ],
);

moon_test(
    name  => 'chain name',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag           => 'div',
            name          => 'one',
            after_element => [
                {
                    tag      => 'div',
                    name     => 'two',
                    children => [
                        {
                            tag  => 'div',
                            name => 'three',
                        }
                    ]
                }
            ]
        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div name="one"></div><div name="two"><div name="three"></div></div>',
        },
        {
            test     => 'obj',
            func     => 'two',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<div name="two"><div name="three"></div></div>',
                },
                {
                    test     => 'obj',
                    func     => 'three',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test     => 'render',
                            expected => '<div name="three"></div>',
                        }
                    ]
                }
            ]
        },
        {
            test     => 'obj',
            func     => 'three',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<div name="three"></div>',
                }
            ]
        }
    ],
);

moon_test(
    name  => 'chain name',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag           => 'div',
            name          => 'three',
            after_element => [
                {
                    tag      => 'div',
                    name     => 'six',
                    children => [
                        {
                            tag  => 'div',
                            name => 'seven',
                        }
                    ]
                }
            ],
            before_element => [
                {
                    tag      => 'div',
                    name     => 'one',
                    children => [
                        {
                            tag  => 'div',
                            name => 'two',
                        }
                    ]
                }
            ],
            children => [
                {
                    tag      => 'div',
                    name     => 'four',
                    children => [
                        {
                            tag  => 'div',
                            name => 'five',
                        }
                    ]
                }
            ]

        }
    },
    instructions => [
        {
            test => 'render',
            expected =>
'<div name="one"><div name="two"></div></div><div name="three"><div name="four"><div name="five"></div></div></div><div name="six"><div name="seven"></div></div>',
        },
        {
            test     => 'obj',
            func     => 'one',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
                      '<div name="one"><div name="two"></div></div>',
                },
                {
                    test     => 'obj',
                    func     => 'two',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test     => 'render',
                            expected => '<div name="two"></div>',
                        }
                    ]
                }
            ]
        },
        {
            test     => 'obj',
            func     => 'five',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<div name="five"></div>',
                }
            ]
        },
        {
            test     => 'obj',
            func     => 'seven',
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test     => 'render',
                    expected => '<div name="seven"></div>',
                }
            ]
        }
    ],
);

sunrise(47, tripping_out);

1;
