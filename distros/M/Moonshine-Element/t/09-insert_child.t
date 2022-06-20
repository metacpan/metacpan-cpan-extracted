use Moonshine::Test qw/:all/;

use Moonshine::Element;
moon_test(
    name => 'after element',
    build => {
        class => 'Moonshine::Element',
        args  => {
            tag   => 'p',
            class => 'apples',
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<p class="apples"></p>',
        },
        {
            test => 'obj',
            func => 'insert_child',
            args => [0, {
                tag   => 'p',
                class => 'pears',
            }],
	    args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="pears"></p>',
                }
            ]
        },
        {
            test => 'render',
            expected => '<p class="apples"><p class="pears"></p></p>',
        },
        {
            test => 'obj',
            func => 'insert_child',
            args => [0, {
                tag   => 'p',
                class => 'oranges',
            }],
	    args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p class="oranges"></p>',
                }
            ]
        },
        {
            test => 'render',
            expected => '<p class="apples"><p class="oranges"></p><p class="pears"></p></p>',
        }
    ]
);

sunrise(10, sprintf " %s ", confused);
