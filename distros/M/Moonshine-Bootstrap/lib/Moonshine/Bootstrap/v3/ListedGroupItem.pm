package Moonshine::Bootstrap::v3::ListedGroupItem;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::Badge',
    'Moonshine::Bootstrap::v3::ListedGroupItemText',
    'Moonshine::Bootstrap::v3::ListedGroupItemHeading',
); 

with 'Moonshine::Bootstrap::Component::ListedGroupItem';

1;


