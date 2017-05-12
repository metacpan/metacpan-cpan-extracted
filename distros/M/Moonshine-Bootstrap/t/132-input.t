use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Input;
use Moonshine::Bootstrap::v3::Input;

moon_test(
    name => 'input',
    build => {
        class => 'Moonshine::Bootstrap::Component::Input',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'input',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<input class="form-control" type="text"></input>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'input',
    build => {
        class => 'Moonshine::Bootstrap::v3::Input',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'input',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<input class="form-control" type="text"></input>',
                }
            ],
        },
    ],
);

sunrise();

1;
