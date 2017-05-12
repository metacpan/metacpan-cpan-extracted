#! perl
use Moonshine::Test qw/:all/;
use Moonshine::Element;

moon_test({
    name => 'build set',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
            data => 'hello'
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<div>hello</div>'
        },
        {
            test => 'obj',
            func => 'set',
            args => {
                tag => 'p',
                class => 'new'   
            },
            expected => 'Moonshine::Element',
        },
        {
            test => 'render',
            expected => '<p class="new">hello</p>'
        }
    ],
});

moon_test({
    name => 'aria-valuemin - 0',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
            data => '0',
            aria_valuemin => '0',
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<div aria-valuemin="0">0</div>'
        },
    ],
});

moon_test({
    name => 'build and set',
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<div></div>'
        },
        {
            test => 'obj',
            func => 'set',
            args => {
                data => '0',
                aria_valuemin => '0'   
            },
            expected => 'Moonshine::Element',
        },
        {
            test => 'render',
            expected => '<div aria-valuemin="0">0</div>'
        },
        {
            catch => 1,
            func => 'set',
            args => [
                'aria_valuemin', '0'  
            ],
            expected => 'args passed to set must be a hashref',
        },
    ],
});

sunrise(11, sprintf " %s ", cute_bear);

1;
