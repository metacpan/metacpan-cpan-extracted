
use strict;
use warnings;

use FindBin;
use lib map $FindBin::Bin . '/' . $_, qw( . ../lib ../lib/perl5 );

use Data::Dumper;

use test;

######################################################################

producer 'SQL::Admin::Driver::DB2::Producer';

test_products integer => (
    [ '1', '1' ],
    [ '0', '0' ],
    [ '-1', '-1' ],
);

test_products data_type => (
    [ 'smallint', 'int2' ],
    [ 'integer',  'int4' ],
    [ 'bigint',   'int8' ],
    [ 'varchar(10)', 'text', { size => 10 } ],
    [ 'decimal', 'decimal' ],
    [ 'decimal(5)', 'decimal', { size => 5, } ],
    [ 'decimal(5,0)', 'decimal', { size => 5, scale => 0 } ],
);

test_products column_name => (
    [ 'aaa'   => 'aaa' ],
    [ '"and"' => 'and' ],
);

test_products ordered_column_name => (
    [ 'aaa'   => { column_name => 'aaa' } ],
    [ '"and"' => { column_name => 'and' } ],
    [ 'aaa asc'   => { column_name => 'aaa', column_order => 'asc' } ],
    [ 'aaa desc'   => { column_name => 'aaa', column_order => 'desc' } ],
);

test_products ordered_column_names => (
    [ 'aaa'        => [ { column_name => 'aaa' } ] ],
    [ '"and"'      => [ { column_name => 'and' } ] ],
    [ 'aaa asc'    => [ { column_name => 'aaa', column_order => 'asc' } ] ],
    [ 'aaa desc'   => [ { column_name => 'aaa', column_order => 'desc' } ] ],
    [ 'aaa, bbb desc, ccc, ddd asc' => [
        { column_name => 'aaa' },
        { column_name => 'bbb', column_order => 'desc' },
        { column_name => 'ccc' },
        { column_name => 'ddd', column_order => 'asc' },
    ]],
);

test_products schema_qualified_name => (
    [ 'aaa',       { name => 'aaa' }, ],
    [ 'bbb.aaa',   { schema => 'bbb', name => 'aaa' }, ],
    [ '"and".aaa', { schema => 'and', name => 'aaa' }, ],
);

test_products sequence_name => (
    [ 'aaa',       { name => 'aaa' }, ],
    [ 'bbb.aaa',   { schema => 'bbb', name => 'aaa' }, ],
    [ '"and".aaa', { schema => 'and', name => 'aaa' }, ],
);


test_products table_name => (
    [ 'aaa',       { name => 'aaa' }, ],
    [ 'bbb.aaa',   { schema => 'bbb', name => 'aaa' }, ],
    [ '"and".aaa', { schema => 'and', name => 'aaa' }, ],
);

test_products view_name => (
    [ 'aaa',       { name => 'aaa' }, ],
    [ 'bbb.aaa',   { schema => 'bbb', name => 'aaa' }, ],
    [ '"and".aaa', { schema => 'and', name => 'aaa' }, ],
);

test_products index_name => (
    [ 'aaa',       { name => 'aaa' }, ],
    [ 'bbb.aaa',   { schema => 'bbb', name => 'aaa' }, ],
    [ '"and".aaa', { schema => 'and', name => 'aaa' }, ],
);

######################################################################
######################################################################

test_products current_timestamp => [ 'current timestamp', 1];
test_products current_time => [ 'current time', 1];
test_products current_date => [ 'current date', 1];

test_products default_clause => (
    [ 'with default 1', { integer => 1 } ],
    [ 'with default \'\'', { string => '' } ],
    [ 'with default \'a\'', { string => 'a' } ],
    [ 'with default current timestamp', { current_timestamp => 1 } ],
);

test_products autoincrement => (
    [ 'generated as identity', {} ],
    [ 'generated as identity (start with 1000)', { sequence_start_with => 1000 } ],
    [ 'generated as identity (start with 1000)', { sequence_start_with => 1000, sequence_increment_by => 1 } ],
    [ 'generated as identity (start with 1000, minvalue 1)', { sequence_start_with => 1000, sequence_minvalue => 1 } ],
    [ 'generated as identity (start with 1000, maxvalue 1)', { sequence_start_with => 1000, sequence_maxvalue => 1 } ],
    [ 'generated as identity (start with 1000, cache 1)', { sequence_start_with => 1000, sequence_cache => 1 } ],
);

######################################################################
######################################################################

test_products create_sequence => (
    [ 'CREATE sequence aaa', {
        sequence_name    => { name => 'aaa' },
    }],
    [ 'CREATE sequence bbb.aaa as bigint', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int8',
    }],
    [ 'CREATE sequence bbb.aaa as integer START WITH 1000', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int4',
        sequence_options => {
            sequence_start_with => 1_000,
        },
    }],
    [ 'CREATE sequence bbb.aaa as integer increment by 133', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int4',
        sequence_options => {
            sequence_increment_by => 133,
        },
    }],
    [ 'CREATE sequence bbb.aaa as integer START WITH 1000 INCREMENT BY 133', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int4',
        sequence_options => {
            sequence_start_with => 1_000,
            sequence_increment_by => 133,
        },
    }],
    [ 'CREATE sequence bbb.aaa as integer START WITH 1000 MINVALUE 1000 MAXVALUE 10000', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int4',
        sequence_options => {
            sequence_start_with => 1_000,
            sequence_minvalue   => 1_000,
            sequence_maxvalue   => 10_000,
        },
    }],
    [ 'CREATE sequence bbb.aaa as integer START WITH 1000 INCREMENT BY 133 CACHE 50', {
        sequence_name => { schema => 'bbb', name => 'aaa' },
        sequence_type => 'int4',
        sequence_options => {
            sequence_start_with => 1_000,
            sequence_increment_by => 133,
            sequence_cache        => 50,
        },
    }],
);

######################################################################
## CREATE INDEX
######################################################################

test_products index_unique => (
    [ 'UNIQUE',    { index_unique => 1 } ],
);

test_products index_column_list => (
    [ '(aaa)'        => [ { column_name => 'aaa' } ] ],
    [ '("and")'      => [ { column_name => 'and' } ] ],
    [ '(aaa asc)'    => [ { column_name => 'aaa', column_order => 'asc' } ] ],
    [ '(aaa desc)'   => [ { column_name => 'aaa', column_order => 'desc' } ] ],
    [ '(aaa, bbb desc, ccc, ddd asc)'   => [
        { column_name => 'aaa' },
        { column_name => 'bbb', column_order => 'desc' },
        { column_name => 'ccc' },
        { column_name => 'ddd', column_order => 'asc' },
    ]],
);

test_products create_index => (
    [ 'CREATE INDEX bbb.aaa ON bbb.ccc (ddd)', {
        index_name        => { schema => 'bbb', name => 'aaa' },
        table_name        => { schema => 'bbb', name => 'ccc' },
        index_column_list => [
            { column_name => 'ddd' },
        ]
    }],
    [ 'CREATE UNIQUE INDEX bbb.aaa ON bbb.ccc (ddd)', {
        index_unique      => 1,
        index_name        => { schema => 'bbb', name => 'aaa' },
        table_name        => { schema => 'bbb', name => 'ccc' },
        index_column_list => [
            { column_name => 'ddd' },
        ]
    }],
    [ 'CREATE INDEX bbb.aaa ON bbb.ccc (ddd asc, eee desc)', {
        index_name        => { schema => 'bbb', name => 'aaa' },
        table_name        => { schema => 'bbb', name => 'ccc' },
        index_column_list => [
            { column_name => 'ddd', column_order => 'asc' },
            { column_name => 'eee', column_order => 'desc' },
        ]
    }],
);


######################################################################
## CREATE TABLE
######################################################################

test_products column_definition => (
    [ 'aaa integer not null', {
        data_type   => 'int4',
        column_not_null    => 1,
        column_name => 'AAA',
    }],
    [ 'aaa varchar(400)', {
        data_type   => 'varchar',
        size        => 400,
        column_name => 'AAA',
    }],
    [ 'aaa smallint not null with default 1', {
        data_type   => 'int2',
        column_not_null    => 1,
        column_name => 'AAA',
        default_clause => { integer => 1 },
    }],
    [ 'aaa integer not null generated as identity (minvalue 1, maxvalue 2147483647)', {
        'autoincrement' => {
            'sequence_increment_by' => 1,
            'sequence_start_with' => 1,
            'sequence_minvalue' => 1,
            'sequence_maxvalue' => 2147483647
        },
        'data_type' => 'int4',
        'column_not_null' => 1,
        'column_name' => 'aaa'
    }],
    [ 'aaa integer not null generated as identity', {
        'autoincrement' => {
        },
        'data_type' => 'int4',
        'column_not_null' => 1,
        'column_name' => 'aaa'
    }],
);

test_products create_table => (
    [ 'create table aaa.bbb (
  ccc  integer not null,
  ddd  SMALLINT     NOT NULL WITH DEFAULT 1,
  eee  SMALLINT     NOT NULL WITH DEFAULT 0,
  fff  VARCHAR(160),
  ggg  VARCHAR(200),
  hhh  SMALLINT     NOT NULL WITH DEFAULT 0,
  iii  VARCHAR(200),
  jjj  TIMESTAMP    NOT NULL WITH DEFAULT current timestamp
)', {
      table_name => { schema => 'aaa', name   => 'bbb', },
      table_content => [
          { column_definition => { data_type => 'int4', column_not_null => 1, column_name => 'ccc' }},
          { column_definition => { data_type => 'int2', column_not_null => 1, column_name => 'ddd', default_clause => { numeric_constant => 1 } } },
          { column_definition => { data_type => 'int2', column_not_null => 1, column_name => 'eee', default_clause => { numeric_constant => 0 } } },
          { column_definition => { data_type => 'varchar', column_name => 'fff', size => 160 } },
          { column_definition => { data_type => 'varchar', column_name => 'ggg', size => 200 } },
          { column_definition => { data_type => 'int2', column_not_null => 1, column_name => 'hhh', default_clause => { numeric_constant => 0 } } },
          { column_definition => { data_type => 'varchar', column_name => 'iii', size => 200 } },
          { column_definition => { data_type => 'timestamp', column_not_null => 1, column_name => 'jjj', default_clause => { current_timestamp => 1 } } },

      ],
  }
]);

######################################################################
## Alter table
######################################################################

test_products constraint_name => (
    [ 'CONSTRAINT aaa', 'aaa' ],
);


test_products column_list => (
    [ '(aaa)', [ 'aaa' ] ],
    [ '(aaa, bbb)', [ 'aaa', 'bbb' ] ],
);

test_products primary_key_constraint => (
    [ 'PRIMARY KEY (aaa) ', {
        column_list => [ 'aaa' ],
    } ],
    [ 'CONSTRAINT cname PRIMARY KEY (aaa) ', {
        constraint_name => 'cname',
        column_list => [ 'aaa' ],
    } ],
);

test_products add_constraint => (
    [ 'ADD PRIMARY KEY (aaa) ', {
        primary_key_constraint => {
            column_list => [ 'aaa' ],
        } } ],
    [ 'ADD CONSTRAINT cname PRIMARY KEY (aaa) ', {
        primary_key_constraint => {
            constraint_name => 'cname',
            column_list => [ 'aaa' ],
        } } ],
);

test_products alter_table_action => (
    [ '', { 'db2_locksize' => 'ROW' } ],
    [ '', { 'db2_append'   => 0     } ],
    [ '', { 'db2_volatile' => 0     } ],
    [ '', { 'db2_log_index' => undef } ],
    [ 'add constraint xyz primary key (aaa)', {
        add_constraint => { primary_key_constraint => {
            constraint_name => 'xyz',
            column_list     => [ 'aaa' ],
        } } } ],
    [ 'add constraint xyz primary key (aaa, bbb)', {
        add_constraint => { primary_key_constraint => {
            constraint_name => 'xyz',
            column_list     => [ 'aaa', 'bbb' ],
        } } } ],
    [ 'add constraint xyz unique (APP_ID, MSISDN)', {
        add_constraint => { unique_constraint => {
            constraint_name => 'xyz',
            column_list     => [ 'APP_ID', 'MSISDN' ],
        } } } ],
    [ 'add constraint xyz foreign key (aaa) references bbb.ccc (ddd) on delete cascade on update no action', {
        add_constraint => { foreign_key_constraint => {
            constraint_name  => 'xyz',
            db2_enforced     => 1,
            db2_optimize     => 0,
            update_rule      => 'no_action',
            delete_rule      => 'cascade',
            referenced_table => { schema => 'bbb', name => 'ccc' },
            referenced_column_list  => [ 'ddd' ],
            referencing_column_list => [ 'aaa' ],
        } } } ],
);

test_products alter_table => (
    [ '', {
        table_name => { schema => 'aaa', name => 'bbb' },
        alter_table_actions => [
            { db2_locksize => 'ROW' },
            { db2_append => 0 },
            { db2_volatile => 0 },
            { db2_log_index => undef },
        ],
    }],
);

test_products statement_insert => (
    [ 'insert into bbb.aaa (ccc, ddd) values (4, 2)', {
        table_name => { schema => 'bbb', name => 'aaa' },
        column_list => [ 'ccc', 'ddd' ],
        insert_value_list => [
            [ { numeric_constant => 4 }, { numeric_constant => 2 } ],
        ]}],

    [ 'insert into bbb.aaa values (4, 2)', {
        table_name => { schema => 'bbb', name => 'aaa' },
        insert_value_list => [
            [ { numeric_constant => 4 }, { numeric_constant => 2 } ],
        ]}],

    [ 'insert into bbb.aaa (ccc, ddd) values (1, null), (2, current timestamp), (3, default)', {
        table_name => { schema => 'bbb', name => 'aaa' },
        column_list => [ 'ccc', 'ddd' ],
        insert_value_list => [
            [ { numeric_constant => 1 }, { null => 1 } ],
            [ { numeric_constant => 2 }, { current_timestamp => 1  } ],
            [ { numeric_constant => 3 }, { default => 1  } ],
        ]}],
)
