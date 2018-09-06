package AutoDiscovery;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table           => 'auto',
    primary_key     => 'id',
    auto_increment  => 'id',
    discover_schema => 1
);

1;
