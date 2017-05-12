package BaseUser;
use strict;
our $db;
use base qw(Rose::DB::Object);

__PACKAGE__->meta->setup(
    db => $db,
    table => 'users',

    columns => [
        id              => { type => 'serial',    not_null => 1 },
        name            => { type => 'varchar',   length   => 255, not_null => 1 },
        password        => { type => 'varchar', not_null => 1, },
    ],

    primary_key_columns => ['id'],

    unique_key => ['name'],

);

1;
