#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (5 * 15);

BEGIN
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

foreach my $db_type (qw(mysql pg informix sqlite oracle))
{
  SKIP:
  {
    unless(have_db($db_type))
    {
      skip("$db_type tests", 15);
    }
  }

  next  unless(have_db($db_type));

  Rose::DB->default_type($db_type);

  my $db = Rose::DB->new;

  my $pk_columns = $db->primary_key_column_names('Rdb_test_pk0');
  ok(ref $pk_columns eq 'ARRAY' && @$pk_columns == 0,  "$db_type no pk columns 1");

  my @pk_columns = $db->primary_key_column_names('Rdb_test_pk0');
  ok(@pk_columns == 0,  "$db_type no pk columns 2");

  if($db_type eq 'pg')
  {
    @pk_columns = $db->primary_key_column_names(schema => 'Rose_db_private',
                                                table  => 'Rdb_test_pk0');
    ok(@pk_columns == 0,  "$db_type no pk columns 3");

    $pk_columns = $db->primary_key_column_names(schema => 'Rose_db_private',
                                                table  => 'Rdb_test_pk0');
    ok(@$pk_columns == 0,  "$db_type no pk columns 4");
  }
  else
  {
    ok(1, "$db_type no pk columns 3");
    ok(1, "$db_type no pk columns 4");
  }

  $pk_columns = $db->primary_key_column_names('Rdb_test_pk1');
  @pk_columns = sort @$pk_columns;

  if($db_type eq 'oracle')
  {
    # Oracle returns names in upper case.
    is_deeply(\@pk_columns, [ 'ID' ], "$db_type pk columns 1");
  }
  else
  {
    is_deeply(\@pk_columns, [ 'id' ], "$db_type pk columns 1");
  }

  @pk_columns = $db->primary_key_column_names('Rdb_test_pk1');
  @pk_columns = sort @pk_columns;

  if($db_type eq 'oracle')
  {
    is_deeply(\@pk_columns, [ 'ID' ], "$db_type pk columns 2");
  }
  else
  {
    is_deeply(\@pk_columns, [ 'id' ], "$db_type pk columns 2");
  }

  ok($db->has_primary_key(table => 'Rdb_test_pk1'), "$db_type pk check 1");
  ok($db_type ne 'pg' || $db->has_primary_key('rdb_test_Pk1'), "$db_type pk check 2");

  $pk_columns = $db->primary_key_column_names('Rdb_test_pk2');
  @pk_columns = sort @$pk_columns;

  if($db_type eq 'oracle')
  {
    # Oracle returns names in upper case.
    is_deeply(\@pk_columns, [ 'ID1', 'ID2' ], "$db_type pk columns 3");
  }
  else
  {
    is_deeply(\@pk_columns, [ 'id1', 'id2' ], "$db_type pk columns 3");
  }

  @pk_columns = $db->primary_key_column_names('Rdb_test_pk2');
  @pk_columns = sort @pk_columns;

  if($db_type eq 'oracle')
  {
    # Oracle returns names in upper case.
    is_deeply(\@pk_columns, [ 'ID1', 'ID2' ], "$db_type pk columns 4");
  }
  else
  {
    is_deeply(\@pk_columns, [ 'id1', 'id2' ], "$db_type pk columns 4");
  }

  ok($db->has_primary_key(table => 'Rdb_test_pk2'), "$db_type pk check 3");
  ok($db_type ne 'pg' || $db->has_primary_key('rdb_test_Pk2'), "$db_type pk check 4");

  if($db_type eq 'pg')
  {
    @pk_columns = $db->primary_key_column_names(schema => 'Rose_db_private',
                                                table  => 'Rdb_test_pk2');
    @pk_columns = sort @pk_columns;
    is_deeply(\@pk_columns, [ 'id1', 'id2' ], "$db_type pk columns 5");

    ok($db->has_primary_key(schema => 'Rose_db_private', table => 'Rdb_test_pk2'), "$db_type pk check 5");
    ok($db->has_primary_key(schema => 'rose_db_Private', table => 'rdb_test_Pk2'), "$db_type pk check 6");
  }
  else
  {
    ok(1, "$db_type pk columns 5");
    ok(1, "$db_type pk check 5");
    ok(1, "$db_type pk check 6");
  }
}

BEGIN
{
  #
  # PostgreSQL
  #

  if(my $dbh = get_dbh('pg_admin'))
  {
    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');

      $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk0 CASCADE');
      $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk1 CASCADE');
      $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk2 CASCADE');

      $dbh->do('DROP SCHEMA Rose_db_private CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk1
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_private.Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_private.Rdb_test_pk1
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_private.Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

#     $dbh->do(<<"EOF");
# CREATE VIEW Rose_db_private.Rdb_test_view AS
#   SELECT * FROM Rose_db_private.Rdb_test_pk1
# EOF

    $dbh->disconnect;
  }

  #
  # Oracle
  #

  if(my $dbh = get_dbh('oracle_admin'))
  {
    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE CONSTRAINTS');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk1
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  if(my $dbh = get_dbh('mysql_admin'))
  {
    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk1
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

    $dbh->disconnect;
  }

  #
  # Informix
  #

  if(my $dbh = get_dbh('informix_admin'))
  {
    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
      $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk1
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

    $dbh->disconnect;
  }


  #
  # SQLite
  #

  if(my $dbh = get_dbh('sqlite_admin'))
  {
    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE Rdb_test_pk0');
      $dbh->do('DROP TABLE Rdb_test_pk1');
      $dbh->do('DROP TABLE Rdb_test_pk2');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk0
(
  name  VARCHAR(255) NOT NULL,
  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk1
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rdb_test_pk2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  PRIMARY KEY(id1, id2),
  UNIQUE(name)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if(have_db('pg_admin') && (my $dbh = get_dbh('pg_admin')))
  {
    $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');

    $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk0 CASCADE');
    $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk1 CASCADE');
    $dbh->do('DROP TABLE Rose_db_private.Rdb_test_pk2 CASCADE');

    $dbh->do('DROP SCHEMA Rose_db_private CASCADE');

    $dbh->disconnect;
  }

  if(have_db('oracle_admin') && (my $dbh = get_dbh('oracle_admin')))
  {
    $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE CONSTRAINTS');

    $dbh->disconnect;
  }

  if(have_db('mysql_admin') && (my $dbh = get_dbh('mysql_admin')))
  {
    $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');

    $dbh->disconnect;
  }

  if(have_db('informix_admin') && (my $dbh = get_dbh('informix_admin')))
  {
    $dbh->do('DROP TABLE Rdb_test_pk0 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk1 CASCADE');
    $dbh->do('DROP TABLE Rdb_test_pk2 CASCADE');

    $dbh->disconnect;
  }  

  if(have_db('sqlite_admin') && (my $dbh = get_dbh('sqlite_admin')))
  {
    $dbh->do('DROP TABLE Rdb_test_pk0');
    $dbh->do('DROP TABLE Rdb_test_pk1');
    $dbh->do('DROP TABLE Rdb_test_pk2');

    $dbh->disconnect;
  } 
}
