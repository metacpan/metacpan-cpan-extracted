#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;

use_ok 'MySQL::Workbench::Parser';

my $mwb = File::Spec->catfile(
    dirname( __FILE__ ),
    'lint.mwb',
);

my $parser = MySQL::Workbench::Parser->new( file => $mwb, lint => 0 );
$parser->_parse;

my ($table2) = grep{ $_->name eq 'table2' }@{ $parser->tables };
my ($column) = grep{ $_->name eq 'UserDefinedTest' }@{ $table2->columns };

is_deeply $column->type_info, {
        'precision' => undef,
        'args' => "'Admin', 'Test'",,
        'name' => 'ENUM',
        'gui_name' => 'user_category',
        'length' => undef
    };

my $check = {
    'com.mysql.rdbms.mysql.datatype.geometry' => {
        'length' => undef,
        'name' => 'GEOMETRY'
    },
    'com.mysql.rdbms.mysql.datatype.tinyint' => {
        'length' => undef,
        'name' => 'TINYINT'
    },
    'com.mysql.rdbms.mysql.datatype.real' => {
        'name' => 'REAL',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.bit' => {
        'name' => 'BIT',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.long' => {
        'gui_name' => 'LONG',
        'name' => 'MEDIUMTEXT',
        'length' => undef,
        'args' => undef,
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.datatype.char' => {
        'name' => 'CHAR',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.blob' => {
        'length' => undef,
        'name' => 'BLOB'
    },
    'com.mysql.rdbms.mysql.datatype.smallint' => {
        'length' => undef,
        'name' => 'SMALLINT'
    },
    'com.mysql.rdbms.mysql.userdatatype.dec' => {
        'precision' => '10,0',
        'args' => '10,0',
        'length' => undef,
        'gui_name' => 'DEC',
        'name' => 'DECIMAL'
    },
    'com.mysql.rdbms.mysql.datatype.time' => {
        'name' => 'TIME',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.int2' => {
        'length' => '6',
        'args' => '6',
        'name' => 'SMALLINT',
        'gui_name' => 'INT2',
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.float4' => {
        'precision' => undef,
        'length' => undef,
        'args' => undef,
        'gui_name' => 'FLOAT4',
        'name' => 'FLOAT'
    },
    'com.mysql.rdbms.mysql.datatype.polygon' => {
        'length' => undef,
        'name' => 'POLYGON'
    },
    'com.mysql.rdbms.mysql.datatype.varchar' => {
        'length' => undef,
        'name' => 'VARCHAR'
    },
    'com.mysql.rdbms.mysql.datatype.mediumtext' => {
        'length' => undef,
        'name' => 'MEDIUMTEXT'
    },
    'com.mysql.rdbms.mysql.datatype.mediumblob' => {
        'name' => 'MEDIUMBLOB',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.int3' => {
        'length' => '9',
        'args' => '9',
        'name' => 'MEDIUMINT',
        'gui_name' => 'INT3',
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.datatype.int' => {
        'length' => undef,
        'name' => 'INT'
    },
    'com.mysql.rdbms.mysql.userdatatype.fixed' => {
        'precision' => '10,0',
        'args' => '10,0',
        'name' => 'DECIMAL',
        'gui_name' => 'FIXED',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.int4' => {
        'precision' => undef,
        'gui_name' => 'INT4',
        'name' => 'INT',
        'length' => '11',
        'args' => '11'
    },
    'com.mysql.rdbms.mysql.datatype.text' => {
        'name' => 'TEXT',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.multipolygon' => {
        'length' => undef,
        'name' => 'MULTIPOLYGON'
    },
    'com.mysql.rdbms.mysql.datatype.tinyblob' => {
        'name' => 'TINYBLOB',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.nvarchar' => {
        'length' => undef,
        'name' => 'NVARCHAR'
    },
    'com.mysql.rdbms.mysql.datatype.multipoint' => {
        'name' => 'MULTIPOINT',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.int8' => {
        'length' => '20',
        'args' => '20',
        'gui_name' => 'INT8',
        'name' => 'BIGINT',
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.character' => {
        'precision' => undef,
        'gui_name' => 'CHARACTER',
        'name' => 'CHAR',
        'length' => '1',
        'args' => '1'
    },
    'com.mysql.rdbms.mysql.userdatatype.float8' => {
        'name' => 'DOUBLE',
        'gui_name' => 'FLOAT8',
        'length' => undef,
        'args' => undef,
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.datatype.longblob' => {
        'name' => 'LONGBLOB',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.linestring' => {
        'length' => undef,
        'name' => 'LINESTRING'
    },
    'com.mysql.rdbms.mysql.userdatatype.longvarchar' => {
        'gui_name' => 'LONG VARCHAR',
        'name' => 'MEDIUMTEXT',
        'length' => undef,
        'args' => undef,
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.integer' => {
        'precision' => undef,
        'name' => 'INT',
        'gui_name' => 'INTEGER',
        'length' => '11',
        'args' => '11'
    },
    'com.mysql.rdbms.mysql.userdatatype.int1' => {
        'precision' => undef,
        'length' => '4',
        'args' => '4',
        'name' => 'TINYINT',
        'gui_name' => 'INT1'
    },
    'com.mysql.rdbms.mysql.datatype.timestamp_f' => {
        'length' => undef,
        'name' => 'TIMESTAMP'
    },
    'com.mysql.rdbms.mysql.datatype.tinytext' => {
        'length' => undef,
        'name' => 'TINYTEXT'
    },
    'com.mysql.rdbms.mysql.datatype.datetime' => {
        'name' => 'DATETIME',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.mediumint' => {
        'length' => undef,
        'name' => 'MEDIUMINT'
    },
    'com.mysql.rdbms.mysql.userdatatype.numeric' => {
        'precision' => '10,0',
        'args' => '10,0',
        'length' => undef,
        'name' => 'DECIMAL',
        'gui_name' => 'NUMERIC'
    },
    'com.mysql.rdbms.mysql.datatype.set' => {
        'name' => 'SET',
        'length' => undef
    },
    'c3a987bc-181e-11e9-9fc3-e09467d90b02' => {
        'precision' => undef,
        'args' => "'Admin', 'Test'",,
        'name' => 'ENUM',
        'gui_name' => 'user_category',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.longtext' => {
        'length' => undef,
        'name' => 'LONGTEXT'
    },
    'com.mysql.rdbms.mysql.datatype.binary' => {
        'name' => 'BINARY',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.float' => {
        'length' => undef,
        'name' => 'FLOAT'
    },
    'com.mysql.rdbms.mysql.datatype.time_f' => {
        'name' => 'TIME',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.json' => {
        'name' => 'JSON',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.middleint' => {
        'gui_name' => 'MIDDLEINT',
        'name' => 'MEDIUMINT',
        'length' => '9',
        'args' => '9',
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.datatype.geometrycollection' => {
        'name' => 'GEOMETRYCOLLECTION',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.datetime_f' => {
        'name' => 'DATETIME',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.bigint' => {
        'name' => 'BIGINT',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.nchar' => {
        'name' => 'NCHAR',
        'length' => undef
     },
    'com.mysql.rdbms.mysql.datatype.timestamp' => {
         'length' => undef,
         'name' => 'TIMESTAMP'
    },
    'com.mysql.rdbms.mysql.datatype.multilinestring' => {
         'name' => 'MULTILINESTRING',
         'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.year' => {
        'length' => undef,
        'name' => 'YEAR'
    },
    'com.mysql.rdbms.mysql.userdatatype.bool' => {
        'precision' => undef,
        'name' => 'TINYINT',
        'gui_name' => 'BOOL',
        'length' => '1',
        'args' => '1'
    },
    'com.mysql.rdbms.mysql.datatype.point' => {
        'name' => 'POINT',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.enum' => {
        'length' => undef,
        'name' => 'ENUM'
    },
    'com.mysql.rdbms.mysql.datatype.varbinary' => {
        'length' => undef,
        'name' => 'VARBINARY'
    },
    'com.mysql.rdbms.mysql.userdatatype.longvarbinary' => {
        'length' => undef,
        'args' => undef,
        'gui_name' => 'LONG VARBINARY',
        'name' => 'MEDIUMBLOB',
        'precision' => undef
    },
    'com.mysql.rdbms.mysql.userdatatype.boolean' => {
        'precision' => undef,
        'args' => 1,
        'gui_name' => 'BOOLEAN',
        'name' => 'TINYINT',
        'length' => '1'
    },
    'com.mysql.rdbms.mysql.datatype.decimal' => {
        'name' => 'DECIMAL',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.date' => {
        'name' => 'DATE',
        'length' => undef
    },
    'com.mysql.rdbms.mysql.datatype.double' => {
        'length' => undef,
        'name' => 'DOUBLE'
    }
};

is_deeply $parser->datatypes, $check;

done_testing();
