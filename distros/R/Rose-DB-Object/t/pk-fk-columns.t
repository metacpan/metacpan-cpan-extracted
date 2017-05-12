#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (4 * 1);

BEGIN
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Loader');
}

our(%Have);

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

  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => 'rose_db_object.*');

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition(braces => 'k&r', indent => 2)
  #    if($class->can('meta'));
  #}

  my $a_class = $class_prefix . '::RoseDbObjectA';
  my $b_class = $class_prefix . '::RoseDbObjectB';

  my $a = $a_class->new(id => 1, name => 'A')->save;
  my $b = $b_class->new(id => 1, name => 'B')->save;

  $b = $b_class->new(id => 1)->load;

  $b->rose_db_object_a(undef);
  eval { $b->save };

  ok(!$@, "pk fk column - $db_type");
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
      $dbh->do('DROP TABLE rose_db_object_b');
      $dbh->do('DROP TABLE rose_db_object_a');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_a
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_b
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255),
  FOREIGN KEY (id) REFERENCES rose_db_object_a (id)
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

    die "MySQL version too old"  unless($db->database_version >= 4_000_000 && 
                                        mysql_supports_innodb());

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_b');
      $dbh->do('DROP TABLE rose_db_object_a');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_a
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
)
ENGINE=InnoDB
EOF
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_b
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255),

  FOREIGN KEY (id) REFERENCES rose_db_object_a (id)
)
ENGINE=InnoDB
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

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_b');
      $dbh->do('DROP TABLE rose_db_object_a');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_a
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_b
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255),
  FOREIGN KEY (id) REFERENCES rose_db_object_a (id)
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

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_b');
      $dbh->do('DROP TABLE rose_db_object_a');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_a
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_b
(
  id    INTEGER NOT NULL PRIMARY KEY,
  name  VARCHAR(255),
  FOREIGN KEY (id) REFERENCES rose_db_object_a (id)
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

    $dbh->do('DROP TABLE rose_db_object_b');
    $dbh->do('DROP TABLE rose_db_object_a');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_b');
    $dbh->do('DROP TABLE rose_db_object_a');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_b');
    $dbh->do('DROP TABLE rose_db_object_a');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_b');
    $dbh->do('DROP TABLE rose_db_object_a');

    $dbh->disconnect;
  }
}
