use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Badge;
use Moonshine::Bootstrap::v3::Badge;

moon_test(
    name => 'badge',
    build => {
        class => 'Moonshine::Bootstrap::Component::Badge',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'badge',
            args   => {
                data => '42',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<span class="badge">42</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'badge',
            expected => 'Moonshine::Element',
            args   => {
                data    => '4',
                wrapper => {
                    tag   => 'button',
                    class => 'btn btn-primary',
                    type  => 'button',
                    data  => 'Messages'
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<button class="btn btn-primary" type="button">Messages<span class="badge">4</span></button>'   
                }
            ],
        },
    ],
);

moon_test(
    name => 'badge',
    build => {
        class => 'Moonshine::Bootstrap::v3::Badge',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'badge',
            args   => {
                data => '42',
            },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<span class="badge">42</span>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'badge',
            expected => 'Moonshine::Element',
            args   => {
                data    => '4',
                wrapper => {
                    tag   => 'button',
                    class => 'btn btn-primary',
                    type  => 'button',
                    data  => 'Messages'
                }
            },
            subtest => [
                {
                    test => 'render',
                    expected => 
'<button class="btn btn-primary" type="button">Messages<span class="badge">4</span></button>'   
                }
            ],
        },
    ],
);

sunrise();
