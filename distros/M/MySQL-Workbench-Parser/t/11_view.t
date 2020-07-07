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
    'view.mwb',
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
        name: cidr
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: col2
        not_null: '0'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - cidr
        name: PRIMARY
        type: PRIMARY
    name: table1
    primary_key:
      - cidr
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: cidr
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: col3
        not_null: '0'
        precision: '-1'
    foreign_keys: {}
    indexes:
      -
        columns:
          - cidr
        name: PRIMARY
        type: PRIMARY
    name: table2
    primary_key:
      - cidr
views:
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: cidr
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: col2
        not_null: '0'
        precision: '-1'
    definition: "CREATE VIEW `view1` AS\n    SELECT \n        cidr, col2\n    FROM\n        table1;"
    name: view1
  -
    columns:
      -
        autoincrement: '0'
        comment: ''
        datatype: INT
        default_value: ''
        length: '-1'
        name: cidr
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: col2
        not_null: '0'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: col3
        not_null: '0'
        precision: '-1'
    definition: "CREATE VIEW `view2` AS\n    SELECT table1.cidr, col2, col3\n    FROM table1\n        INNER JOIN table2\n            ON table1.cidr = table2.cidr;"
    name: view2
|;

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
is_string $parser->dump, $check;

ok $parser->dom;

my $all_tables = $parser->tables || [];
is scalar(@{$all_tables}), 2, 'Got the correct number of tables';

my $all_views = $parser->views || [];
is scalar(@{$all_views}), 2, 'Got the correct number of views';

my $view = $all_views->[0];
ok $view, 'Got a view';

is $view->name, 'view1';

my @columns = @{ $view->columns || [] };
is_deeply [ map{ $_->name }@columns ], [qw/cidr col2/], "Check columns of view";

is_deeply $view->tables, [qw/table1/], "Check tables the view depends on";
is_deeply $all_views->[1]->tables, [qw/table1 table2/], "Check tables the view2 depends on";

done_testing();
