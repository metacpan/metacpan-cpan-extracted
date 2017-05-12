use Moonshine::Test qw/:all/;

use Moonshine::Parser::HTML;

moon_test(
    name         => 'parse a basic tag',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse',
            args => [ '<div><p class="cats" name="running">Time</p></div>' ],
            args_list => 1,
            expected  => 'Moonshine::Element',
            subtest   => [
                {
                    test => 'render',
                    expected =>
                      '<div><p class="cats" name="running">Time</p></div>',
                },
                {
                    test     => 'obj',
                    func     => 'running',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test => 'render',
                            expected =>
                              '<p class="cats" name="running">Time</p>',
                        },
                        {
                            test     => 'ref_key_scalar',
                            key      => 'class',
                            expected => 'cats',
                        },
                    ]
                },
            ]
        }
    ]
);

moon_test(
    name         => 'parse two p tags inside a wrapper div',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse',
            args => [
'<div><p class="cats" name="running">Time</p><p class="awake" name="sleep">Fine</p></div>'
            ],
            args_list => 1,
            expected  => 'Moonshine::Element',
            subtest   => [
                {
                    test => 'render',
                    expected =>
'<div><p class="cats" name="running">Time</p><p class="awake" name="sleep">Fine</p></div>'
                },
                {
                    test     => 'obj',
                    func     => 'running',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test => 'render',
                            expected =>
                              '<p class="cats" name="running">Time</p>',
                        },
                        {
                            test     => 'ref_key_scalar',
                            key      => 'class',
                            expected => 'cats',
                        },
                    ]
                },
                {
                    test     => 'obj',
                    func     => 'sleep',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test => 'render',
                            expected =>
                              '<p class="awake" name="sleep">Fine</p>',
                        },
                        {
                            test     => 'ref_key_scalar',
                            key      => 'class',
                            expected => 'awake',
                        },
                    ]
                },

            ]
        }
    ]
);

moon_test(
    name         => 'parse two p tags no wrapper div',
    build => {
        class => 'Moonshine::Parser::HTML',
    },
    instructions => [
        {
            test => 'obj',
            func => 'parse',
            args => [
'<p class="cats" name="running">Time</p><p class="awake" name="sleep">Fine</p>'
            ],
            args_list => 1,
            expected  => 'Moonshine::Element',
            subtest   => [
                {
                    test => 'render',
                    expected =>
'<p class="cats" name="running">Time</p><p class="awake" name="sleep">Fine</p>'
                },
                {
                    test     => 'obj',
                    func     => 'sleep',
                    expected => 'Moonshine::Element',
                    subtest  => [
                        {
                            test => 'render',
                            expected =>
                              '<p class="awake" name="sleep">Fine</p>',
                        },
                        {
                            test     => 'ref_key_scalar',
                            key      => 'class',
                            expected => 'awake',
                        },
                    ]
                },

            ]
        }
    ]
);

sunrise();
