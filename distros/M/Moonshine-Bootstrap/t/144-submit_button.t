use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::SubmitButton;
use Moonshine::Bootstrap::v3::SubmitButton;

moon_test(
    name => 'submit_button',
    build => {
        class => 'Moonshine::Bootstrap::Component::SubmitButton',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'submit_button',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success" type="submit">Submit</button>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'submit_button v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::SubmitButton',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'submit_button',
            expected => 'Moonshine::Element',
            args   => {
                switch => 'success',
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-success" type="submit">Submit</button>',
                }
            ],
        },
    ],
);

sunrise();

1;
