use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::DropdownButton;
use Moonshine::Bootstrap::v3::DropdownButton;

moon_test(
    name => 'dropdown component',
    build => {
        class => 'Moonshine::Bootstrap::Component::DropdownButton',        
    },
    instructions => [
         {
            test => 'obj',
            func => 'dropdown_button',
            args   => {
                id   => 'dropdownMenu1',
                data => 'Dropdown',
            },
			expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected =>'<button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown">Dropdown<span class="caret"></span></button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_button',
            args   => {
                split => 1,
                id    => 'dropdownMenu1',
                data  => 'Dropdown',
            },
			expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-default" type="button">Dropdown</button><button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown"><span class="caret"></span></button>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'dropdown_button v3 component',
    build => {
        class => 'Moonshine::Bootstrap::v3::DropdownButton',        
    },
    instructions => [
         {
            test => 'obj',
            func => 'dropdown_button',
            args   => {
                id   => 'dropdownMenu1',
                data => 'Dropdown',
            },
			expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected =>'<button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown">Dropdown<span class="caret"></span></button>'
                }
            ],
        },
        {
            test => 'obj',
            func => 'dropdown_button',
            args   => {
                split => 1,
                id    => 'dropdownMenu1',
                data  => 'Dropdown',
            },
			expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<button class="btn btn-default" type="button">Dropdown</button><button class="dropdown-toggle btn btn-default" id="dropdownMenu1" type="button" aria-expanded="true" aria-haspopup="true" data-toggle="dropdown"><span class="caret"></span></button>'
                }
            ],
        },
    ],
);

sunrise();
