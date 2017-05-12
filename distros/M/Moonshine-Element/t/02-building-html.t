#! perl
use Moonshine::Test qw/:all/;

use Moonshine::Element;

moon_test({
    name => 'test de basics',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'p',
            data => ['hello'],
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<p>hello</p>',
        },
        {
            test => 'scalar',
            func => 'text',
            expected => 'hello',
        },
        {
            test => 'obj',
            func => 'add_before_element',
            args => {
                tag => 'p',
                data => ['one'],
                class => 'two',
            },
            expected => 'Moonshine::Element',
            subtest => [
                 {
                    test => 'ref_key_scalar',
                    key => 'tag',
                    expected => 'p',
                 },
                 {
                    test => 'scalar',
                    func => 'text',
                    expected => 'one',
                 },
                 {
                    test => 'ref_key_scalar',
                    key => 'class',
                    expected => 'two',
                 },
                 {
                    test => 'render',
                    expected => '<p class="two">one</p>',
                 }
            ],
        },
        {
            test => 'render',
            expected => '<p class="two">one</p><p>hello</p>',
        },
        {
            test => 'obj',
            func => 'add_after_element',
            args => {
                tag => 'p',
                data => ['four'],
                class => 'three',
            },
            expected => 'Moonshine::Element',
            subtest => [
                 {
                    test => 'ref_key_scalar',
                    key => 'tag',
                    expected => 'p',
                 },
                 {
                    test => 'scalar',
                    func => 'text',
                    expected => 'four',
                 },
                 {
                    test => 'ref_key_scalar',
                    key => 'class',
                    expected => 'three',
                 },
                 {
                    test => 'render',
                    expected => '<p class="three">four</p>',
                 }
            ],
        },
        {
            test => 'render',
            expected => '<p class="two">one</p><p>hello</p><p class="three">four</p>'
        },
        {
            test => 'scalar',
            func => 'text',
            expected => 'hello',
        }
    ]
});

my $child1 = Moonshine::Element->new({ tag => 'p', data => ['test'] });
my $child2 = Moonshine::Element->new({ tag => 'p', data => ['test'] });
my $child3 = Moonshine::Element->new({ tag => 'p', data => ['test'] });

moon_test({
    name => 'object',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
        }
    },
    instructions => [
        {
            test => 'obj',
            func => 'add_child',
            args => $child1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'obj',
                    func => 'add_after_element',
                    args => $child2,
                    expected => 'Moonshine::Element',
                },
                {
                    test => 'obj',
                    func => 'add_before_element',
                    args => $child3,
                    expected => 'Moonshine::Element',
                }
            ]
        },
        {
            test => 'render',
            expected => '<div><p>test</p><p>test</p><p>test</p></div>'
        }
    ],
});

moon_test({
    name => 'a complicated html page... :)',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'html',
        }
    },
    instructions => [
        {
            test => 'obj',
            func => 'add_child',
            args => {
                tag => 'head',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render', 
                    expected => '<head></head>',
                },
                {
                    test => 'obj',
                    func => 'add_child',
                    args => {
                        tag => 'title',
                        data => ['Page Title'],
                    },
                    expected => 'Moonshine::Element',
                    subtest => [
                        {
                            test => 'render',
                            expected => '<title>Page Title</title>',
                        }
                    ],
                },
                {
                    test => 'render',
                    expected => '<head><title>Page Title</title></head>',
                }
            ]
        },
        {
            test => 'obj',
            func => 'add_child',
            args => {
                tag => 'body',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'obj',
                    func => 'add_child',
                    args => {
                        tag => 'h1',
                        id => 'page-header',
                        class => 'big',
                        data=> ['Title'],
                    },
                    expected => 'Moonshine::Element',
                    subtest => [
                        {
                            test => 'obj',
                            func => 'add_after_element',
                            args => {
                                tag => 'p',
                                data => ['Add some content here'],
                            },
                            expected => 'Moonshine::Element',
                            subtest => [
                                {
                                    test => 'render',
                                    expected => '<p>Add some content here</p>'
                                }
                            ],
                        },
                    ],
                },
            ],
        },
        {
            test => 'render',
            expected => '<html><head><title>Page Title</title></head><body><h1 class="big" id="page-header">Title</h1><p>Add some content here</p></body></html>',
        }
    ],
});

moon_test({
    name => 'test de basics',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'p',
            data => ['hello'],
            class => {
                1 => 'a',
                2 => 'b',
                3 => 'c',
            }
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<p class="a b c">hello</p>',
        },
        {
            test => 'array',
            func => 'has_class',
            expected => [ 1, 2, 3 ],
        },
        {
            test => 'undef',
            func => 'clear_class',
            expected => 'Moonshine::Element',
        },
        {
            test => 'true',
            func => 'class',
            args => {
                a => 1,
                b => 2,
                c => 3,
            },         
        },
        {
            test => 'render',
            expected => '<p class="1 2 3">hello</p>',
        },
        {
            test => 'true',
            func => 'class',
            args => {
                a => 3,
                c => 1,
            },
        },
        {
            test => 'render',
            expected => '<p class="3 2 1">hello</p>',
        },
        {
            test => 'true',
            func => 'class',
            args => [ qw/a b c/ ],
        },
        {
            test => 'render',
            expected => '<p class="a b c">hello</p>',
        },
    ]
});

my $child4 = Moonshine::Element->new({ tag => 'p', data => ['tester'] });

moon_test(
    name => 'ooo',
    instance => $child1,
    instructions => [
        {
            test => 'render',
            expected => '<p>test</p>',
        },
        {
            func => 'build_element',
            args => [
                $child4,
            ],
            args_list => 1,
            test => 'obj',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p>tester</p>',
                }
            ],
        },
        {
            func => 'build_element',
            catch => 1,
            args => [
                bless {}, 'NotOnTheMoon',
            ],
            args_list => 1,
            expected => 'I\'m not a Moonshine::Element',
        }
    ]
);

sunrise(56, innocent . love);

1;
