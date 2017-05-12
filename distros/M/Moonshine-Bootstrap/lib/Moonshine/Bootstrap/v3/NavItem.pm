package Moonshine::Bootstrap::v3::NavItem;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::LinkedLi',
    'Moonshine::Bootstrap::v3::DropdownUl',
); 

with 'Moonshine::Bootstrap::Component::NavItem';

1;


