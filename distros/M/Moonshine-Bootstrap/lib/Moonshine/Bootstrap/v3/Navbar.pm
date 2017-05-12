package Moonshine::Bootstrap::v3::Navbar;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::NavbarHeader',
    'Moonshine::Bootstrap::v3::NavbarCollapse',
);

with 'Moonshine::Bootstrap::Component::Navbar';

1;


