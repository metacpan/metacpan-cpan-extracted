#!/usr/bin/perl

use Rose::DB;

Rose::DB->register_db(driver => 'sqlite');

package JCS::A;
use base 'Rose::DB::Object';

__PACKAGE__->meta->setup
(
  columns => [ qw(id a) ],

  relationships =>
  [
    bs =>
    {
      type => 'many to many',
      map_class => 'JCS::AtoB',
      manager_args => { with_map_records => 1 },
    },
  ],
);

package JCS::B;
use base 'Rose::DB::Object';

__PACKAGE__->meta->setup
(
  columns => [ qw(id b) ],
);

package JCS::C;
use base 'Rose::DB::Object';

__PACKAGE__->meta->setup
(
  columns => [ qw(id c) ],

  relationships =>
  [
    bs =>
    {
      type => 'many to many',
      map_class => 'JCS::CtoB',
      manager_args => { with_map_records => 1 },
    },
  ],
);

package JCS::AtoB;
use base 'Rose::DB::Object';

__PACKAGE__->meta->setup
(
  columns => [ qw(id a_id b_id) ],
  foreign_keys =>
  [
    a_id =>
    {
      class => 'JCS::A',
      key_columns => { a_id => 'id' },
    },

    b_id =>
    {
      class => 'JCS::B',
      key_columns => { b_id => 'id' },
    }
  ],
);

package JCS::CtoB;
use base 'Rose::DB::Object';

__PACKAGE__->meta->setup
(
  columns => [ qw(id c_id b_id) ],
  foreign_keys =>
  [
    a_id =>
    {
      class => 'JCS::C',
      key_columns => { c_id => 'id' },
    },

    b_id =>
    {
      class => 'JCS::B',
      key_columns => { b_id => 'id' },
    }
  ],
);
