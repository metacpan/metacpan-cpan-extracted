#!/usr/bin/perl -w

use strict;

use Test::More tests => 82;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
}

our(%HAVE, $DID_SETUP);

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

foreach my $db_type (qw(mysql pg pg_with_schema informix sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 16)  unless($HAVE{$db_type});
  }

  next  unless($HAVE{$db_type});

  Rose::DB->default_type($db_type);

  unless($DID_SETUP++)
  {
    #
    # Setup classes
    #

    package MD;

    our @ISA = qw(Rose::DB::Object);

    MD->meta->table('Rose_db_object_MD');

    MD->meta->columns(ID => { primary_key => 1 });

    MD->meta->relationships
    (
      'mdvs' =>
      {
        type  => 'one to many',
        class => 'MDV',
        column_map => { ID => 'MD' },
      }
    );

    MD->meta->initialize;

    package MD::Mgr;

    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MD' }

    Rose::DB::Object::Manager->make_manager_methods('mds');

    package MDV;

    our @ISA = qw(Rose::DB::Object);

    MDV->meta->table('Rose_db_object_MDV');

    MDV->meta->columns
    (
      ID => { primary_key => 1 },
      MD => { type => 'int' },
    );

    MDV->meta->relationships
    (
      'md' =>
      {
        type  => 'many to one',
        class => 'MD',
        column_map => { MD => 'ID' },
      }
    );

    MDV->meta->initialize;
  }
  #else
  #{
  #  MD->meta->init_with_db(Rose::DB->new);
  #  MDV->meta->init_with_db(Rose::DB->new);
  #}

  # Add data
  my $dbh = MD->init_db->retain_dbh;

  my $schema = $db_type eq 'pg_with_schema' ? 'Rose_db_object_private.' : '';
  for(1 .. 3)
  {
    $dbh->do("INSERT INTO ${schema}Rose_db_object_MD (ID) VALUES ($_)");
  }

  for(1 .. 2)
  {
    $dbh->do("INSERT INTO ${schema}Rose_db_object_MDV (ID, MD) VALUES ($_, 1)");
  }

  # Run tests

  my $i = 0;

  foreach my $arg (qw(MD mdvs.MD t2.MD Rose_db_object_MDV.MD))
  {
    $i++;
    my $mds = MD::Mgr->get_mds(distinct     => 1,
                               with_objects => [ 'mdvs' ],
                               query        => [ 'MD' => undef ],
                               sort_by      => 'ID');

    ok($mds, "get_mds() $i.1 - $db_type");
    ok(@$mds == 2, "get_mds() $i.2 - $db_type");
    is($mds->[0]->ID, 2, "get_mds() $i.3 - $db_type");
    is($mds->[1]->ID, 3, "get_mds() $i.4 - $db_type");
  }
}

BEGIN
{
  our %HAVE;

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
    $HAVE{'pg'} = 1;
    $HAVE{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_MD');
      $dbh->do('DROP TABLE Rose_db_object_MDV');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_MD');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_MDV');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MD
(
  ID SERIAL NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MDV
(
  ID SERIAL NOT NULL PRIMARY KEY,
  MD INT NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_MD
(
  ID SERIAL NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_MDV
(
  ID SERIAL NOT NULL PRIMARY KEY,
  MD INT NOT NULL
)
EOF

    $dbh->disconnect;
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
    $HAVE{'mysql'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_MD');
      $dbh->do('DROP TABLE Rose_db_object_MDV');
    }

    our $PG_HAS_CHKPASS = 1  unless($@);

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MD
(
  ID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MDV
(
  ID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  MD INT NOT NULL
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
    $HAVE{'informix'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_MD');
      $dbh->do('DROP TABLE Rose_db_object_MDV');
    }

    our $PG_HAS_CHKPASS = 1  unless($@);

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MD
(
  ID SERIAL NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MDV
(
  ID SERIAL NOT NULL PRIMARY KEY,
  MD INT NOT NULL
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
    $HAVE{'sqlite'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_MD');
      $dbh->do('DROP TABLE Rose_db_object_MDV');
    }

    our $PG_HAS_CHKPASS = 1  unless($@);

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MD
(
  ID INTEGER PRIMARY KEY AUTOINCREMENT
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_MDV
(
  ID INTEGER PRIMARY KEY AUTOINCREMENT,
  MD INT NOT NULL
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test table

  if($HAVE{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_MD');
    $dbh->do('DROP TABLE Rose_db_object_MDV');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_MD');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_MDV');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($HAVE{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_MD');
    $dbh->do('DROP TABLE Rose_db_object_MDV');

    $dbh->disconnect;
  }

  if($HAVE{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_MD');
    $dbh->do('DROP TABLE Rose_db_object_MDV');

    $dbh->disconnect;
  }

  if($HAVE{'sqlite'})
  {
    # SQLite
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_MD');
    $dbh->do('DROP TABLE Rose_db_object_MDV');

    $dbh->disconnect;
  }
}
