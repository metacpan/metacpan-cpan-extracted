#!/usr/bin/perl -w

use strict;

use Test::More tests => 51;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
  use_ok('Rose::DB::Object::MakeMethods::Generic');
}

our($HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg)) #pg_with_schema
{
  skip("PostgreSQL tests", 12)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  my $o = MyPgObject->new(id    => 1,
                          name  => 'John',  
                          fkone => 1,
                          fk2   => 2,
                          fk3   => 3);

  ok($o->save, "object save() 1 - $db_type");

  my $fo = MyPgOtherObject->new(id   => 1,
                                name => 'Foo',
                                k1   => 1,
                                ktwo => 2,
                                k3   => 3);

  ok($fo->save, "object save() 2 - $db_type");

  $fo = MyPgOtherObject->new(id   => 2,
                             name => 'Bar',
                             k1   => 1,
                             ktwo => 2,
                             k3   => 3);

  ok($fo->save, "object save() 3 - $db_type");

  $fo = MyPgOtherObject->new(id   => 3,
                             name => 'bar 2',
                             k1   => 1,
                             ktwo => 2,
                             k3   => 3);

  ok($fo->save, "object save() 4 - $db_type");

  $fo = MyPgOtherObject->new(id   => 4,
                             name => 'Baz',
                             k1   => 2,
                             ktwo => 3,
                             k3   => 4);

  ok($fo->save, "object save() 5 - $db_type");

  my $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 3, "get objects 1 - $db_type");

  is($objs->[0]->id, 2, "get objects 2 - $db_type");
  is($objs->[1]->id, 3, "get objects 3 - $db_type");
  is($objs->[2]->id, 1, "get objects 4 - $db_type");

  $o->fkone(2);
  $o->fk2(3);
  $o->fk3(4);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 1, "get objects 5 - $db_type");

  is($objs->[0]->id, 4, "get objects 6 - $db_type");

  $o->fkone(7);
  $o->fk2(8);
  $o->fk3(9);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 0, "get objects 7 - $db_type");
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 12)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(id    => 1,
                             name  => 'John',  
                             fkone => 1,
                             fk2   => 2,
                             fk3   => 3);

  ok($o->save, "object save() 1 - $db_type");

  my $fo = MyMySQLOtherObject->new(id   => 1,
                                   name => 'Foo',
                                   k1   => 1,
                                   ktwo => 2,
                                   k3   => 3);

  ok($fo->save, "object save() 2 - $db_type");

  $fo = MyMySQLOtherObject->new(id   => 2,
                                name => 'Bar',
                                k1   => 1,
                                ktwo => 2,
                                k3   => 3);

  ok($fo->save, "object save() 3 - $db_type");

  $fo = MyMySQLOtherObject->new(id   => 3,
                                name => 'bar 2',
                                k1   => 1,
                                ktwo => 2,
                                k3   => 3);

  ok($fo->save, "object save() 4 - $db_type");

  $fo = MyMySQLOtherObject->new(id   => 4,
                                name => 'Baz',
                                k1   => 2,
                                ktwo => 3,
                                k3   => 4);

  ok($fo->save, "object save() 5 - $db_type");

  my $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 3, "get objects 1 - $db_type");

  is($objs->[0]->id, 2, "get objects 2 - $db_type");
  is($objs->[1]->id, 3, "get objects 3 - $db_type");
  is($objs->[2]->id, 1, "get objects 4 - $db_type");

  $o->fkone(2);
  $o->fk2(3);
  $o->fk3(4);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 1, "get objects 5 - $db_type");

  is($objs->[0]->id, 4, "get objects 6 - $db_type");

  $o->fkone(7);
  $o->fk2(8);
  $o->fk3(9);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 0, "get objects 7 - $db_type");
}

#
# Informix
#

SKIP: foreach my $db_type (qw(informix))
{
  skip("Informix tests", 12)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(id    => 1,
                                name  => 'John',  
                                fkone => 1,
                                fk2   => 2,
                                fk3   => 3);

  ok($o->save, "object save() 1 - $db_type");

  my $fo = MyInformixOtherObject->new(id   => 1,
                                      name => 'Foo',
                                      k1   => 1,
                                      ktwo => 2,
                                      k3   => 3);

  ok($fo->save, "object save() 2 - $db_type");

  $fo = MyInformixOtherObject->new(id   => 2,
                                   name => 'Bar',
                                   k1   => 1,
                                   ktwo => 2,
                                   k3   => 3);

  ok($fo->save, "object save() 3 - $db_type");

  $fo = MyInformixOtherObject->new(id   => 3,
                                   name => 'bar 2',
                                   k1   => 1,
                                   ktwo => 2,
                                   k3   => 3);

  ok($fo->save, "object save() 4 - $db_type");

  $fo = MyInformixOtherObject->new(id   => 4,
                                   name => 'Baz',
                                   k1   => 2,
                                   ktwo => 3,
                                   k3   => 4);

  ok($fo->save, "object save() 5 - $db_type");

  my $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 3, "get objects 1 - $db_type");

  is($objs->[0]->id, 2, "get objects 2 - $db_type");
  is($objs->[1]->id, 3, "get objects 3 - $db_type");
  is($objs->[2]->id, 1, "get objects 4 - $db_type");

  $o->fkone(2);
  $o->fk2(3);
  $o->fk3(4);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 1, "get objects 5 - $db_type");

  is($objs->[0]->id, 4, "get objects 6 - $db_type");

  $o->fkone(7);
  $o->fk2(8);
  $o->fk3(9);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 0, "get objects 7 - $db_type");
}

#
# SQLite
#

SKIP: foreach my $db_type (qw(sqlite))
{
  skip("SQLite tests", 12)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $o = MySQLiteObject->new(id    => 1,
                              name  => 'John',  
                              fkone => 1,
                              fk2   => 2,
                              fk3   => 3);

  ok($o->save, "object save() 1 - $db_type");

  my $fo = MySQLiteOtherObject->new(id   => 1,
                                    name => 'Foo',
                                    k1   => 1,
                                    ktwo => 2,
                                    k3   => 3);

  ok($fo->save, "object save() 2 - $db_type");

  $fo = MySQLiteOtherObject->new(id   => 2,
                                 name => 'Bar',
                                 k1   => 1,
                                 ktwo => 2,
                                 k3   => 3);

  ok($fo->save, "object save() 3 - $db_type");

  $fo = MySQLiteOtherObject->new(id   => 3,
                                 name => 'bar 2',
                                 k1   => 1,
                                 ktwo => 2,
                                 k3   => 3);

  ok($fo->save, "object save() 4 - $db_type");

  $fo = MySQLiteOtherObject->new(id   => 4,
                                 name => 'Baz',
                                 k1   => 2,
                                 ktwo => 3,
                                 k3   => 4);

  ok($fo->save, "object save() 5 - $db_type");

  my $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 3, "get objects 1 - $db_type");

  is($objs->[0]->id, 2, "get objects 2 - $db_type");
  is($objs->[1]->id, 3, "get objects 3 - $db_type");
  is($objs->[2]->id, 1, "get objects 4 - $db_type");

  $o->fkone(2);
  $o->fk2(3);
  $o->fk3(4);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 1, "get objects 5 - $db_type");

  is($objs->[0]->id, 4, "get objects 6 - $db_type");

  $o->fkone(7);
  $o->fk2(8);
  $o->fk3(9);
  $o->other_objs(undef);

  $objs = $o->other_objs;

  ok($objs && ref $objs eq 'ARRAY' && @$objs == 0, "get objects 7 - $db_type");
}

BEGIN
{
  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_PG = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_other');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  id    INT NOT NULL PRIMARY KEY,
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass

    package MyPgOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgOtherObject->meta->table('rose_db_object_other');

    MyPgOtherObject->meta->columns
    (
      id   => { primary_key => 1 },
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyPgOtherObject->meta->alias_column(k2 => 'ktwo');

    MyPgOtherObject->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,
  fk1   INT,
  fk2   INT,
  fk3   INT
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('rose_db_object_test');

    MyPgObject->meta->columns
    (
      'name',
      id  => { primary_key => 1 },
      fk1 => { type => 'int' },
      fk2 => { type => 'int' },
      fk3 => { type => 'int' },
    );

    MyPgObject->meta->alias_column(fk1 => 'fkone');
    MyPgObject->meta->initialize;

    Rose::DB::Object::MakeMethods::Generic->import
    (
      objects_by_key =>
      [
        other_objs => 
        {
          class => 'MyPgOtherObject',
          key_columns =>
          {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
          },
          manager_args => { sort_by => 'LOWER(name)' },
          query_args   => [ name => { ne => 'foo' } ],
        },
      ]
    );
  }

  #
  # MySQL
  #

  eval 
  {
    $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_MYSQL = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_other');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  id    INT NOT NULL PRIMARY KEY,
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass

    package MyMySQLOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLOtherObject->meta->table('rose_db_object_other');

    MyMySQLOtherObject->meta->columns
    (
      id   => { primary_key => 1 },
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyMySQLOtherObject->meta->alias_column(k2 => 'ktwo');

    MyMySQLOtherObject->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,
  fk1   INT,
  fk2   INT,
  fk3   INT
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      'name',
      id  => { primary_key => 1 },
      fk1 => { type => 'int' },
      fk2 => { type => 'int' },
      fk3 => { type => 'int' },
    );

    MyMySQLObject->meta->alias_column(fk1 => 'fkone');
    MyMySQLObject->meta->initialize;

    Rose::DB::Object::MakeMethods::Generic->import
    (
      objects_by_key =>
      [
        other_objs => 
        {
          class => 'MyMySQLOtherObject',
          key_columns =>
          {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
          },
          manager_args => { sort_by => 'LOWER(name)' },
        },
      ]
    );
  }

  #
  # Informix
  #

  eval 
  {
    $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_INFORMIX = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_other');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  id    INT NOT NULL PRIMARY KEY,
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass

    package MyInformixOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixOtherObject->meta->table('rose_db_object_other');

    MyInformixOtherObject->meta->columns
    (
      id   => { primary_key => 1 },
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyInformixOtherObject->meta->alias_column(k2 => 'ktwo');

    MyInformixOtherObject->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,
  fk1   INT,
  fk2   INT,
  fk3   INT
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyInformixObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->columns
    (
      'name',
      id  => { primary_key => 1 },
      fk1 => { type => 'int' },
      fk2 => { type => 'int' },
      fk3 => { type => 'int' },
    );

    MyInformixObject->meta->alias_column(fk1 => 'fkone');
    MyInformixObject->meta->initialize;

    Rose::DB::Object::MakeMethods::Generic->import
    (
      objects_by_key =>
      [
        other_objs => 
        {
          class => 'MyInformixOtherObject',
          key_columns =>
          {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
          },
          manager_args => { sort_by => 'LOWER(name)' },
        },
      ]
    );
  }

  #
  # SQLite
  #

  eval 
  {
    $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_SQLITE = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_other');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  id    INT NOT NULL PRIMARY KEY,
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass

    package MySQLiteOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteOtherObject->meta->table('rose_db_object_other');

    MySQLiteOtherObject->meta->columns
    (
      id   => { primary_key => 1 },
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MySQLiteOtherObject->meta->alias_column(k2 => 'ktwo');

    MySQLiteOtherObject->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL,
  fk1   INT,
  fk2   INT,
  fk3   INT
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MySQLiteObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
    (
      'name',
      id  => { primary_key => 1 },
      fk1 => { type => 'int' },
      fk2 => { type => 'int' },
      fk3 => { type => 'int' },
    );

    MySQLiteObject->meta->alias_column(fk1 => 'fkone');
    MySQLiteObject->meta->initialize;

    Rose::DB::Object::MakeMethods::Generic->import
    (
      objects_by_key =>
      [
        other_objs => 
        {
          class => 'MySQLiteOtherObject',
          key_columns =>
          {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
          },
          manager_args => { sort_by => 'LOWER(name)' },
        },
      ]
    );
  }
}

END
{
  # Delete test tables

  if($HAVE_PG)
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');

    $dbh->disconnect;
  }

  if($HAVE_SQLITE)
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');

    $dbh->disconnect;
  }
}

