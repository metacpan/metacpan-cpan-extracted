use Moonshine::Test qw/:all/;
use Moonshine::Element;

moon_test(
    name => 'get_element_by_id - first child - easy - ' . kirby,
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
            children => [
                {
                    tag => 'p',
                    id => 'findme',
                    data => [ 'Hey', 'You' ],
                }
            ] 
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<div><p id="findme">Hey You</p></div>',
        },
        {
            test => 'obj',
            func => 'get_element_by_id',
            args => [ 'findme' ],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p id="findme">Hey You</p>',
                }
            ]
        }
    ]
);

moon_test(
    name => 'get_element_by_id - after_element - - ' . strut,
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
            children => [
                {
                    tag => 'p',
                    data => [ 'Twice' ],
                }
            ],
            after_element => [
                {
                    tag => 'p',
                    id => 'findme',
                    data => [ 'Why', 'are', 'you', 'here' ],
                }
            ], 
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<div><p>Twice</p></div><p id="findme">Why are you here</p>',
        },
        {
            test => 'obj',
            func => 'get_element_by_id',
            args => ['findme'],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p id="findme">Why are you here</p>',
                }
            ]
        }
    ]
);

moon_test(
    name => 'get_element_by_id - before_element - - ' . pointing,
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'div',
            children => [
                {
                    tag => 'p',
                    data => [ 'Locked', 'in', 'a', 'corridor' ],
                }
            ],
            before_element => [
                {
                    tag => 'p',
                    id => 'findme',
                    data => [ 'Fifth', 'Floor' ],
                }
            ], 
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<p id="findme">Fifth Floor</p><div><p>Locked in a corridor</p></div>',
        },
        {
            test => 'obj',
            func => 'get_element_by_id',
            args => ['findme'],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<p id="findme">Fifth Floor</p>',
                }
            ]
        }
    ]
);

moon_test(
    name => 'get_element_by_id - data - - ' . chasing,
    build => {
        class => 'Moonshine::Element',
        args => {
            tag => 'p',
            data => [
                'Bright',
                {
                    tag => 'small',
                    id => 'findme',
                    data => [ 'Who', 'let', 'you', 'in' ],
                },
                'White',
            ],
        }
    },
    instructions => [
        {
            test => 'render',
            expected => '<p>Bright <small id="findme">Who let you in</small> White</p>',
        },
        {
            test => 'obj',
            func => 'get_element_by_id',
            args => ['findme'],
            args_list => 1,
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<small id="findme">Who let you in</small>',
                }
            ]
        },
        {
            test => 'undef',
            func => 'get_element_by_id',
            args => ['nothere'],
            args_list => 1,
        },
        {
            catch => 1,
            func => 'get_element_by_id',
            args => ['nothere'],
            expected => 'first param passed to get_element_by_id not a scalar.',
        }
    ]
);

sunrise(22, zombie);
