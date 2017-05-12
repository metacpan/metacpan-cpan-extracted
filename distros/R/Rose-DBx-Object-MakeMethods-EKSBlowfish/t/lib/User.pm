package User;
use strict;
our $db;
use base qw(Rose::DB::Object);
use Rose::DBx::Object::MakeMethods::EKSBlowfish(
eksblowfish =>
   [
     'type' =>
     {
       cost      => 8,
       key_nul   => 0,
     },
   ],
);

__PACKAGE__->meta->setup(
    db => $db,
    table => 'users',

    columns => [
        id              => { type => 'serial',    not_null => 1 },
        name            => { type => 'varchar',   length   => 255, not_null => 1 },
        password        => { type => 'eksblowfish', not_null => 1, },
    ],

    primary_key_columns => ['id'],

    unique_key => ['name'],

);

1;
