#!/usr/bin/perl -w

use strict;

use Data::Dumper;
use Test::More tests => 4;

BEGIN 
{
  use_ok('Rose::DB::SQLite');
}

my $sql =<<"EOF";
 create  table foo
 (
   name varchar(255),
   id   int primary key,


   unique(name)
 )
EOF

my @r = Rose::DB::SQLite->_info_from_sql($sql);
#print Dumper(\@r);

is_deeply(\@r, 
[
  [
    {
      'NULLABLE' => 1,
      'CHAR_OCTET_LENGTH' => '255',
      'COLUMN_SIZE' => '255',
      'ORDINAL_POSITION' => 1,
      'TYPE_NAME' => 'varchar',
      'COLUMN_NAME' => 'name'
    },
    {
      'NULLABLE' => 1,
      'ORDINAL_POSITION' => 2,
      'TYPE_NAME' => 'int',
      'COLUMN_NAME' => 'id'
    }
  ],
  [
    'id'
  ],
  [
    [
      'name'
    ]
  ]
],
'sqlite parse 1');

$sql =<<"EOF";
 create  table foo
 (
   name varchar(255),
   id   int primary key,

   primary key ( id  ,  name ) ,  
   unique ( name )
 )
EOF

@r = Rose::DB::SQLite->_info_from_sql($sql);
#print Dumper(\@r);

is_deeply(\@r, 
[
  [
    {
      'NULLABLE' => 1,
      'CHAR_OCTET_LENGTH' => '255',
      'COLUMN_SIZE' => '255',
      'ORDINAL_POSITION' => 1,
      'TYPE_NAME' => 'varchar',
      'COLUMN_NAME' => 'name'
    },
    {
      'NULLABLE' => 1,
      'ORDINAL_POSITION' => 2,
      'TYPE_NAME' => 'int',
      'COLUMN_NAME' => 'id'
    }
  ],
  [
    'id',
    'name'
  ],
  [
    [
      'name'
    ]
  ]
],
'sqlite parse 2');

$sql =<<"EOF";
 create  table foo
 (
   name varchar(255) not null default "Jo""h'n'" ,
   baz not null references blah (id),
    blee DATETIME not null default '2005-01-21 12:34:56', -- test
   id   int CONSTRAINT foo not null ON Conflict fAil
            CONSTRAINT bar primary key AUTOINCREMENT 
            DEFAULT 
/*

  This is a bug -- comment
    foo bar -- baz --
*/
            123

            CHECK(fo ( bar b ( 'a''z' ) ) ),
    str varchar ( 64 ) not null default '-- "foo" '' -- /* blah */',
   unique ( 'name' ),
   Foreign KEY 'foo''bar' (id)  references  `blah ` ( 'a', b , asd)
)   /*
foo
bar
create table
blah
    This is legal!
    See: http://www.sqlite.org/lang_comment.html

EOF

@r = Rose::DB::SQLite->_info_from_sql($sql);
#print Dumper(\@r);

is_deeply(\@r, 
[
  [
    {
      'NULLABLE' => 0,
      'CHAR_OCTET_LENGTH' => '255',
      'COLUMN_SIZE' => '255',
      'COLUMN_DEF' => 'Jo"h\'n\'',
      'ORDINAL_POSITION' => 1,
      'TYPE_NAME' => 'varchar',
      'COLUMN_NAME' => 'name'
    },
    {
      'NULLABLE' => 0,
      'ORDINAL_POSITION' => 2,
      'TYPE_NAME' => 'scalar',
      'COLUMN_NAME' => 'baz'
    },
    {
      'NULLABLE' => 0,
      'COLUMN_DEF' => '2005-01-21 12:34:56',
      'ORDINAL_POSITION' => 3,
      'TYPE_NAME' => 'DATETIME',
      'COLUMN_NAME' => 'blee'
    },
    {
      'NULLABLE' => 0,
      'COLUMN_DEF' => '123',
      'ORDINAL_POSITION' => 4,
      'TYPE_NAME' => 'serial',
      'COLUMN_NAME' => 'id'
    },
    {
      'NULLABLE' => 0,
      'CHAR_OCTET_LENGTH' => '64',
      'COLUMN_SIZE' => '64',
      'COLUMN_DEF' => '-- "foo" \' -- /* blah */',
      'ORDINAL_POSITION' => 5,
      'TYPE_NAME' => 'varchar',
      'COLUMN_NAME' => 'str'
    }
  ],
  [
    'id'
  ],
  [
    [
      'name'
    ]
  ]
],
'sqlite parse 3');
