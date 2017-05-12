use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::InputGroup;
use Moonshine::Bootstrap::v3::InputGroup;

moon_test(
    name  => 'input_group',
    build => {
        class => 'Moonshine::Bootstrap::Component::InputGroup',
    },
    instructions => [
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid    => 'basic-addon1',
                sizing => 'lg',
                input  => {
                    placeholder => 'Username',
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group input-group-lg"><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                lid   => 'basic-username',
                label => {
                    data => 'Some text',
                },
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
                right => {
                    data => q(@),
                },

            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<label for="basic-username">Some text</label><div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" id="basic-username" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
    ],
);

moon_test(
    name  => 'input_group',
    build => {
        class => 'Moonshine::Bootstrap::v3::InputGroup',
    },
    instructions => [
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid    => 'basic-addon1',
                sizing => 'lg',
                input  => {
                    placeholder => 'Username',
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group input-group-lg"><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
                right => {
                    data => q(@),
                },
            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'input_group',
            args => {
                mid   => 'basic-addon1',
                lid   => 'basic-username',
                label => {
                    data => 'Some text',
                },
                input => {
                    placeholder => 'Username',
                },
                left => {
                    data => q(@),
                },
                right => {
                    data => q(@),
                },

            },
            expected => 'Moonshine::Element',
            subtest  => [
                {
                    test => 'render',
                    expected =>
'<label for="basic-username">Some text</label><div class="input-group"><span class="input-group-addon" id="basic-addon1">@</span><input class="form-control" id="basic-username" placeholder="Username" type="text" aria-describedby="basic-addon1"></input><span class="input-group-addon" id="basic-addon1">@</span></div>',
                }
            ],
        },
    ],
);




sunrise();
