package Moonshine::Bootstrap::v3::Pagination;

use Moonshine::Magic;

extends (
    'Moonshine::Bootstrap::Component',
    'Moonshine::Bootstrap::v3::LinkedLi',
    'Moonshine::Bootstrap::v3::LinkedLiSpan',
); 

with 'Moonshine::Bootstrap::Component::Pagination';

1;


