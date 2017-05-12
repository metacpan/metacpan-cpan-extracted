package Moonshine::Bootstrap::v3::InputGroupAddon;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::Input',
    'Moonshine::Bootstrap::v3::DropdownButton',
    'Moonshine::Bootstrap::v3::DropdownUl',
);

with 'Moonshine::Bootstrap::Component::InputGroupAddon';

1;


