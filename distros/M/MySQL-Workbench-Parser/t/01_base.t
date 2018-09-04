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
    'test.mwb',
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
        name: user_id
        not_null: '1'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - user_id
        name: PRIMARY
        type: PRIMARY
    name: tm_user
    primary_key:
      - user_id
  -
    columns:
      -
        autoincrement: '0'
        comment: "\t"
        datatype: INT
        default_value: ''
        length: '-1'
        name: speisen_id
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
      -
        autoincrement: '0'
        comment: ''
        datatype: DECIMAL
        default_value: ''
        length: '-1'
        name: speisencol
        not_null: '0'
        precision: 10,0
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: speisencol1
        not_null: '0'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: table1_id
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: table1_id1
        not_null: '1'
        precision: '-1'
    foreign_keys:
      table1:
        -
          foreign: table1_id
          me: table1_id
          on_delete: 'no action'
          on_update: 'no action'
        -
          foreign: table1_id
          me: table1_id1
          on_delete: 'no action'
          on_update: 'no action'
    indexes:
      -
        columns:
          - speisen_id
          - name
        name: PRIMARY
        type: PRIMARY
      -
        columns:
          - table1_id
        name: fk_speisen_table1
        type: INDEX
      -
        columns:
          - table1_id1
        name: fk_speisen_table11
        type: INDEX
    name: speisen
    primary_key:
      - speisen_id
      - name
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: table1_id
        not_null: '1'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - table1_id
        name: PRIMARY
        type: PRIMARY
    name: table1
    primary_key:
      - table1_id
|;

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
is_string $parser->dump, $check;


done_testing();
