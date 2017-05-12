use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::DropdownHeaderLi;
use Moonshine::Bootstrap::v3::DropdownHeaderLi;

moon_test(
    name => 'dropdown_header_li',
    build => {
        class => 'Moonshine::Bootstrap::Component::DropdownHeaderLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'dropdown_header_li',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="dropdown-header"></li>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'dropdown_header_li v3',
    build => {
        class => 'Moonshine::Bootstrap::v3::DropdownHeaderLi',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'dropdown_header_li',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<li class="dropdown-header"></li>',
                }
            ],
        },
    ],
);

sunrise();

1;
