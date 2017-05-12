package Moonshine::Bootstrap::v3::DropdownUl;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::LinkedLi',
    'Moonshine::Bootstrap::v3::SeparatorLi',
    'Moonshine::Bootstrap::v3::DropdownHeaderLi',
); 

with 'Moonshine::Bootstrap::Component::DropdownUl';

1;


