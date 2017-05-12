package Moonshine::Bootstrap::v3::Dropdown;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::DropdownButton',   
    'Moonshine::Bootstrap::v3::DropdownUl',   
); 

with 'Moonshine::Bootstrap::Component::Dropdown';

1;


