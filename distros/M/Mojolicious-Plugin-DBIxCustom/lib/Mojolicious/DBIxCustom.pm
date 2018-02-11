package Mojolicious::DBIxCustom;
use strict;
use warnings;

use DBIx::Custom -base;

sub last_id{
  shift->select("LAST_INSERT_ID()")->value;
}

sub count{
  shift->select(@_,
    after_build_sql => sub{
      "select count(*) from ($_[0]) as t"
    })->value;
}

1;