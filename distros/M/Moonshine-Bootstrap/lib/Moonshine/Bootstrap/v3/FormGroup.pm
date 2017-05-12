package Moonshine::Bootstrap::v3::FormGroup;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::SubmitButton',
    'Moonshine::Bootstrap::v3::Input',
); 

with 'Moonshine::Bootstrap::Component::FormGroup';

1;


