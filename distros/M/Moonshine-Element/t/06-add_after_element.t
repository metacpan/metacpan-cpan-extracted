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
            func => 'add_after_element',
            args => {
                tag   => 'p',
                class => 'pears',
            },
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
            expected => '<p class="apples"></p><p class="pears"></p>',
        }
    ]
);

sunrise(6, sprintf " %s ", confused);
