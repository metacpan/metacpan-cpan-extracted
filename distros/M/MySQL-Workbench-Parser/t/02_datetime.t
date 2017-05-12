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
    'date.mwb',
);

my $check = q|---
tables:
  -
    columns:
      -
        autoincrement: '0'
        datatype: INT
        default_value: ''
        length: '-1'
        name: id
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: action
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        datatype: DATETIME
        default_value: ''
        length: '-1'
        name: create_time
        not_null: '0'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - id
        name: PRIMARY
        type: PRIMARY
    name: history
    primary_key:
      - id
|;

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
is_string $parser->dump, $check;

done_testing();
