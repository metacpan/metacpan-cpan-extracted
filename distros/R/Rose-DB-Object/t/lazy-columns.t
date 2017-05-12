#!/usr/bin/perl -w

use strict;

use Test::More tests => 80;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
  use_ok('Rose::DateTime::Util');
}

use Rose::DB::Object::Util qw(column_value_formatted_key);
use Rose::DateTime::Util qw(parse_date);

our(%Have, $Did_Setup);

#
# Setup
#

SETUP:
{
  package MyObject;

  our @ISA = qw(Rose::DB::Object);

  MyObject->meta->table('Rose_db_object_test');

  MyObject->meta->columns
  (
    id       => { primary_key => 1, not_null => 1 },
    name     => { type => 'varchar', length => 32 },
    code     => { type => 'varchar', length => 32, load_on_demand => 1, inflate => sub { uc $_[1] } },
    start    => { type => 'date', default => '12/24/1980', lazy => 1 },
    ended    => { type => 'date', default => '11/22/2003' },
    date_created => { type => 'timestamp' },
  );
}

#
# Tests
#

my @dbs = qw(mysql pg pg_with_schema informix sqlite);
eval { require List::Util };
@dbs = List::Util::shuffle(@dbs)  unless($@);

# Good test orders:
#@dbs = qw(pg mysql sqlite pg_with_schema informix);

#print "# db type order: @dbs\n";

foreach my $db_type (@dbs)
{
  SKIP:
  {
    # 15
    skip("$db_type tests", 15)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  if($Did_Setup++)
  {
    MyObject->meta->allow_inline_column_values(1);
  }
  else
  {
    eval { MyObject->meta->column('id')->lazy(1) };
    ok($@, 'lazy pk 1');

    MyObject->meta->primary_key_columns('code');

    eval { MyObject->meta->initialize };
    ok($@, 'lazy pk 2');

    MyObject->meta->primary_key_columns('id');
    MyObject->meta->initialize;
  }

  #MyObject->meta->init_with_db(Rose::DB->new);

  ##
  ## Run tests
  ##

  my $o = MyObject->new(name  => 'John', 
                        code  => 'abc', 
                        start => '10/20/2002', 
                        ended => '5/6/2004');

  $o->save;

  $o = MyObject->new(id => $o->id);
  $o->load;

  ok(!defined $o->{'code'}, "lazy check 1 - $db_type");
  ok(!defined $o->{'start'}, "lazy check 2 - $db_type");

  is($o->code, 'ABC', "lazy load 1 - $db_type");
  is($o->start->ymd, '2002-10-20', "lazy load 2 - $db_type");
  is($o->ended->ymd, '2004-05-06', "load 1 - $db_type");

  $o = MyObject->new(id => $o->id);
  $o->load;

  is($o->start->ymd, '2002-10-20', "lazy load 3 - $db_type");

  $o->name('Foo');
  $o->save;

  $o = MyObject->new(id => $o->id);
  $o->load;

  ok(!defined $o->{'code'}, "lazy check 3 - $db_type");
  ok(!defined $o->{'start'}, "lazy check 4 - $db_type");

  is($o->name, 'Foo', "load 2 - $db_type");

  is($o->code, 'ABC', "lazy load 4 - $db_type");
  is($o->start->ymd, '2002-10-20', "lazy load 5 - $db_type");

  $o = MyObject->new(id => $o->id);

  $o->load(nonlazy => 1);

  is($o->{'code'}, 'abc', "nonlazy check 1 - $db_type");
  my $key = column_value_formatted_key(MyObject->meta->column('start')->hash_key);
  ok(defined $o->{$key,$o->db->driver}, "nonlazy check 2 - $db_type");

  $o->code(undef);
  $o->save;

  $o = MyObject->new(id => $o->id);
  $o->load;

  ok(!defined $o->{'code'}, "lazy check 5 - $db_type");
  $o->code('def');
  $o->save;

  $o = MyObject->new(id => $o->id);
  $o->load(nonlazy => 1);

  is($o->{'code'}, 'def', "nonlazy check 3 - $db_type");

  #$DB::single = 1;
  #$Rose::DB::Object::Debug = 1;
}

SKIP:
{
  skip("all db tests", 2)  unless($Did_Setup);
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
      $dbh->do('DROP TABLE Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test');
      $dbh->do('DROP SCHEMA Rose_db_object_private');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          DATE,
  date_created   TIMESTAMP
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          DATE,
  date_created   TIMESTAMP
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
      $dbh->do('DROP TABLE Rose_db_object_test');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          DATE,
  date_created   TIMESTAMP
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

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE DEFAULT '12/24/1980' NOT NULL,
  ended          DATE,
  date_created   DATETIME YEAR TO SECOND
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
      $dbh->do('DROP TABLE Rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE DEFAULT '1980-12-24' NOT NULL,
  ended          DATE,
  date_created   DATETIME
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

    $dbh->do('DROP TABLE Rose_db_object_test');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test');
    $dbh->do('DROP SCHEMA Rose_db_object_private');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # SQLite
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test');

    $dbh->disconnect;
  }
}
