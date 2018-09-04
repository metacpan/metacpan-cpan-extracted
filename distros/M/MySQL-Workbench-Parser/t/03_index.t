#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Basename;
use File::Spec;

use_ok 'MySQL::Workbench::Parser';

my $mwb = File::Spec->catfile(
    dirname( __FILE__ ),
    'index.mwb',
);

my $check = q|---
tables:
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: idusers
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: user_name
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: nick
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: company
        not_null: '0'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - idusers
        name: PRIMARY
        type: PRIMARY
      -
        columns:
          - user_name
        name: user_name_UNIQUE
        type: UNIQUE
      -
        columns:
          - nick
        name: nick_UNIQUE
        type: UNIQUE
    name: users
    primary_key:
      - idusers
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: group_id
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: name
        not_null: '1'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - group_id
        name: PRIMARY
        type: PRIMARY
      -
        columns:
          - name
        name: name_UNIQUE
        type: UNIQUE
    name: groups
    primary_key:
      - group_id
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: user_id
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: group_id
        not_null: '1'
        precision: '-1'
    foreign_keys:
      groups:
        -
          foreign: group_id
          me: group_id
          on_delete: 'no action'
          on_update: 'no action'
      users:
        -
          foreign: idusers
          me: user_id
          on_delete: 'no action'
          on_update: 'no action'
    indexes:
      -
        columns:
          - user_id
          - group_id
        name: PRIMARY
        type: PRIMARY
      -
        columns:
          - group_id
        name: fk_users_has_groups_groups1_idx
        type: INDEX
      -
        columns:
          - user_id
        name: fk_users_has_groups_users_idx
        type: INDEX
    name: user_groups
    primary_key:
      - user_id
      - group_id
|;

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
is_string $parser->dump, $check;

done_testing();
