package Table;

use strict;
use warnings;

use base 'ObjectDB';

__PACKAGE__->meta(
    table   => 'table',
    columns => [
        qw/foo bar baz/,
        'nullable'   => {is_null => 1},
        with_default => {default => '123'}
    ],
);

1;
