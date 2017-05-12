package Moonshine::Bootstrap::v3::DropdownButton;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::Button',
    'Moonshine::Bootstrap::v3::Caret',
); 

with 'Moonshine::Bootstrap::Component::DropdownButton';

1;


