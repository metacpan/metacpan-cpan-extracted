package Moonshine::Bootstrap::v3::Panel;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::PanelHeader',
    'Moonshine::Bootstrap::v3::PanelBody',
    'Moonshine::Bootstrap::v3::PanelFooter',
); 

with 'Moonshine::Bootstrap::Component::Panel';

1;


