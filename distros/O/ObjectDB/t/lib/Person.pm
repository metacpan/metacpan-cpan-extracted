package Person;

use strict;
use warnings;

use base 'TestDB';

__PACKAGE__->meta(
    table          => 'person',
    columns        => [qw/id name/, profession => {default => 'slacker'}],
    primary_key    => 'id',
    auto_increment => 'id',
    unique_keys    => 'name'
);

1;
