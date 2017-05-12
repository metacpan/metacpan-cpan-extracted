package Moonshine::Bootstrap::v3::NavbarHeader;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::LinkImage',
    'Moonshine::Bootstrap::v3::NavbarToggle',
    'Moonshine::Bootstrap::v3::NavbarBrand',
);

with 'Moonshine::Bootstrap::Component::NavbarHeader';

1;


