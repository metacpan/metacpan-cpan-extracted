#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (1 * 4);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

foreach my $db_type (qw(mysql pg informix sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 1)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB::Object::Metadata->unregister_all_classes;
  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => [ 'rose_db_object_uk_test' ]);

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition if($class->can('meta'));
  #}

  my $class = $class_prefix . '::RoseDbObjectUkTest';

  $class->new(a => 1, b => 2, c => 3)->save;

  my $o = $class->new(a => 1, c => 3);

  ok($o->load(speculative => 1), "unique key precedence 1 - $db_type");
}

BEGIN
{
  our %Have;

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
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE rose_db_object_uk_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_uk_test
(
  id   SERIAL NOT NULL PRIMARY KEY, 
  a    INT,
  b    INT,
  c    INT,

  UNIQUE(a, b, c),
  UNIQUE(a, c)
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE rose_db_object_uk_test');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_uk_test
(
  id   INT AUTO_INCREMENT PRIMARY KEY, 
  a    INT,
  b    INT,
  c    INT,

  UNIQUE(a, b, c),
  UNIQUE(a, c)
)
EOF

    $dbh->disconnect;
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
    $Have{'informix'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE rose_db_object_uk_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_uk_test
(
  id   SERIAL NOT NULL PRIMARY KEY, 
  a    INT,
  b    INT,
  c    INT,

  UNIQUE(a, b, c),
  UNIQUE(a, c)
)
EOF

    $dbh->disconnect;
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
    $Have{'sqlite'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE rose_db_object_uk_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_uk_test
(
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  a    INT,
  b    INT,
  c    INT,

  UNIQUE(a, b, c),
  UNIQUE(a, c)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test table

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_uk_test');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_uk_test');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_uk_test');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_uk_test');

    $dbh->disconnect;
  }
}
