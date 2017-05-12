package Moonshine::Bootstrap::v3::ButtonGroup;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
	'Moonshine::Bootstrap::v3::Button',
	'Moonshine::Bootstrap::v3::Dropdown',
); 

with 'Moonshine::Bootstrap::Component::ButtonGroup';

1;


