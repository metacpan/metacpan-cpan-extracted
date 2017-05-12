package Moonshine::Bootstrap::v3::NavbarCollapse;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::NavbarNav',
    'Moonshine::Bootstrap::v3::NavbarButton',
    'Moonshine::Bootstrap::v3::NavbarForm',
    'Moonshine::Bootstrap::v3::NavbarText',
    'Moonshine::Bootstrap::v3::NavbarTextLink',
);

with 'Moonshine::Bootstrap::Component::NavbarCollapse';

1;


