#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
}

if(defined $ENV{'RDBO_NESTED_JOINS'} && Rose::DB::Object::Manager->can('default_nested_joins'))
{
  Rose::DB::Object::Manager->default_nested_joins($ENV{'RDBO_NESTED_JOINS'});
}

our %Have;

#
# Tests
#

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 1)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class = ucfirst($db_type) . '::A';

  my $as =
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => $class,
      with_objects => [ 'bs.c' ]);

  is(scalar @$as, 2, "check count - $db_type");
}

BEGIN
{
  our %Have;

  #
  # MySQL
  #

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test_b');
      $dbh->do('DROP TABLE rose_db_object_test_a');
      $dbh->do('DROP TABLE rose_db_object_test_c');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test_a
(
  id   INT PRIMARY KEY, 
  name VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test_c
(
  id   INT PRIMARY KEY,
  name VARCHAR(255));
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test_b 
(
  id   INT PRIMARY KEY,
  name VARCHAR(255),
  a_id INT NOT NULL REFERENCES a (id),
  c_id INT NOT NULL REFERENCES c (id)
)
EOF

    Rose::DB->default_type('mysql');

    package Mysql::A;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'rose_db_object_test_a',

      columns => [ qw(id name) ],

      relationships =>
      [
        bs =>
        {
          type => 'one to many',
          class => 'Mysql::B',
          column_map => { id => 'a_id' },
        },
      ],
    );

    package Mysql::B;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'rose_db_object_test_b',

      columns => 
      [
        id => { type => 'serial', primary_key => 1 },
        name => { type => 'varchar', length => 255 },
        a_id => { type => 'integer', not_null => 1 },
        c_id => { type => 'integer', not_null => 1 },
      ],

      foreign_keys =>
      [
        a =>
        {
          class => 'Mysql::A',
          key_columns => { a_id => 'id' },
        },

        c =>
        {
          class => 'Mysql::C',
          key_columns => { a_id => 'id' },
        }
      ],
    );

    package Mysql::C;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'rose_db_object_test_c',

      columns => 
      [
        id => { type => 'serial', primary_key => 1 },
        name => { type => 'varchar', length => 255 },
      ]
    );

    $dbh->do("insert into rose_db_object_test_a (id, name) values (1, 'one')");
    $dbh->do("insert into rose_db_object_test_a (id, name) values (2, 'two')");
    $dbh->do("insert into rose_db_object_test_c (id, name) values (1, 'c one')");
    $dbh->do("insert into rose_db_object_test_c (id, name) values (2, 'c two')");
    $dbh->do("insert into rose_db_object_test_b (id, name, a_id, c_id) values (1, 'b one', 1, 1)");

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test_b');
    $dbh->do('DROP TABLE rose_db_object_test_a');
    $dbh->do('DROP TABLE rose_db_object_test_c');
    $dbh->disconnect;
  }
}
