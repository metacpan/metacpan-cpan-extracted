#!/usr/bin/perl -w

use strict;

use Test::More tests => 33;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our %Have;

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

SKIP:
{
  skip("migration tests", 32)  unless($Have{'pg'} && $Have{'mysql'});

  #$DB::single = 1;
  #$Rose::DB::Object::Debug = 1;

  my $db_pg = Rose::DB->new('pg');
  my $db_ws = Rose::DB->new('pg_with_schema');
  my $db_my = Rose::DB->new('mysql');

  my $a1 = Album->new(id => 1, db => $db_pg, name => 'One', year => 2001, dt => '1/2/2003 4:56:12')->save;
  my $a2 = Album->new(id => 2, db => $db_pg, name => 'Two', year => 2002, dt => '2/2/2003 4:56:12')->save;
  my $a3 = Album->new(id => 1, db => $db_ws, name => 'OneWS', year => 2003, dt => '3/2/2003 4:56:12')->save;
  my $a4 = Album->new(id => 2, db => $db_my, name => 'TwoMy', year => 2004, dt => '4/2/2003 4:56:12')->save;

  # pg -> pg with schema
  $a2->db($db_ws);
  $a2->delete;
  $a2->save;

  $a2 = Album->new(id => 2, db => $db_ws)->load;
  is($a2->name, 'Two', 'pg -> pg with schema');

  # pg with schema -> pg
  $a3->db($db_pg);
  $a3->save;

  $a3 = Album->new(id => 1, db => $db_pg)->load;
  is($a3->name, 'OneWS', 'pg with schema -> pg');

  $a1 = Album->new(id => 1, db => $db_pg)->load;
  $a2 = Album->new(id => 2, db => $db_pg)->load;
  $a3 = Album->new(id => 1, db => $db_ws)->load;
  $a4 = Album->new(id => 2, db => $db_my)->load;

  # pg -> mysql
  $a2->db($db_my);
  $a2->delete;
  $a2->save;

  $a2 = Album->new(id => 2, db => $db_my)->load;
  is($a2->name, 'Two', 'pg -> mysql');

  # pg with schema -> mysql
  $a3->db($db_my);
  $a3->delete;
  $a3->save;

  $a3 = Album->new(id => 1, db => $db_my)->load;
  is($a3->name, 'OneWS', 'pg with schema -> mysql 1');
  is($a3->dt->month, 3, 'pg with schema -> mysql 2');

  $a1 = Album->new(id => 1, db => $db_pg)->load;
  $a2 = Album->new(id => 2, db => $db_pg)->load;
  $a3 = Album->new(id => 1, db => $db_ws)->load;
  $a4 = Album->new(id => 2, db => $db_my)->load;

  $a4->name('TwoMy');
  $a4->save;

  # mysql -> pg
  $a4->db($db_pg);
  $a4->save;

  $a4 = Album->new(id => 2, db => $db_my)->load;
  is($a4->name, 'TwoMy', 'mysql -> pg');

  # mysql -> pg with schema
  $a4 = Album->new(id => 2, db => $db_my)->load;
  $a4->db($db_ws);

  $a4->save;

  $a4 = Album->new(id => 2, db => $db_ws)->load;
  is($a4->name, 'TwoMy', 'mysql -> pg with schema');

  $a1 = Album->new(id => 1, db => $db_pg)->load;
  $a2 = Album->new(id => 2, db => $db_pg)->load;
  $a3 = Album->new(id => 1, db => $db_ws)->load;
  $a4 = Album->new(id => 2, db => $db_my)->load;

  is($a1->dt->month, 3, 'dt check 1');
  is($a2->dt->month, 2, 'dt check 2');

  is($a3->dt->month, 3, 'dt check 2');
  is($a4->dt->month, 2, 'dt check 3');

  #
  # Test with schema override
  #

  # Rose::DB::MySQL currently supports schema as a stand-in for database.
  # We need to turn that off for this test because we don't control the
  # database(s) the test suite runs against.
  Rose::DB::MySQL->supports_schema(0);

  $a1 = AlbumWS->new(id => 10, db => $db_pg, name => 'Ten', year => 2001, dt => '1/2/2003 4:56:12')->save;
  $a2 = AlbumWS->new(id => 20, db => $db_pg, name => 'Twe', year => 2002, dt => '2/2/2003 4:56:12')->save;
  $a3 = AlbumWS->new(id => 30, db => $db_ws, name => 'Thi', year => 2003, dt => '3/2/2003 4:56:12')->save;
  $a4 = AlbumWS->new(id => 40, db => $db_my, name => 'For', year => 2004, dt => '4/2/2003 4:56:12')->save;

  $a1->db($db_my);
  $a1->save(insert => 1);
  $a1 = AlbumWS->new(id => 10, db => $db_my)->load;
  is($a1->name, 'Ten', 'pg forced schema -> mysql 1');
  is($a1->dt->month, 1, 'pg forced schema -> mysql 2');

  $a2->db($db_my);
  $a2->save(insert => 1);
  $a2 = AlbumWS->new(id => 20, db => $db_my)->load;
  is($a2->name, 'Twe', 'pg forced schema -> mysql 3');
  is($a2->dt->month, 2, 'pg forced schema -> mysql 4');

  $a3->db($db_my);
  $a3->save(insert => 1);
  $a3 = AlbumWS->new(id => 30, db => $db_my)->load;
  is($a3->name, 'Thi', 'pg forced schema -> mysql 5');
  is($a3->dt->month, 3, 'pg forced schema -> mysql 6');

  $a4->db($db_pg);
  $a4->save(insert => 1);
  $a4 = AlbumWS->new(id => 40, db => $db_ws)->load;
  is($a4->name, 'For', 'mysql -> pg forced schema 7');
  is($a4->dt->month, 4, 'pg forced schema -> mysql 8');

  #
  # Test multi-pk with sequences
  #

  $a1 = Code->new(name => 'One', db => $db_pg, id2 => 2)->save;
  $a2 = Code->new(name => 'Two', db => $db_ws, id2 => 3)->save;

  $a3 = Code->new(name => 'Thr', db => $db_my, id2 => 5, id3 => 6)->save;

  is($a1->id1, 1, 'multi-pk check pk 1');
  is($a1->id2, 2, 'multi-pk check pk 2');
  is($a1->id3, 1, 'multi-pk check pk 3');

  is($a2->id1, 1, 'multi-pk check pk 4');
  is($a2->id2, 3, 'multi-pk check pk 5');
  is($a2->id3, 2, 'multi-pk check pk 6');

  is($a3->id1, 1, 'multi-pk check pk 7');
  is($a3->id2, 5, 'multi-pk check pk 8');
  is($a3->id3, 6, 'multi-pk check pk 9');

  # pg -> mysql
  $a1->db($db_my);
  $a1->delete;
  $a1->save;
  $a1 = Code->new(id1 => 1, id2 => 2, id3 => 1)->load;
  is($a1->name, 'One', 'multi-pk pg -> mysql');

  # pg with schema -> mysql
  $a2->db($db_my);
  $a2->save(insert => 1);
  $a2 = Code->new(id1 => 1, id2 => 3, id3 => 2, db => $db_my)->load;
  is($a2->name, 'Two', 'multi-pk pg with schema -> mysql');

  # mysql -> pg
  $a3->db($db_pg);
  $a3->save(insert => 1);
  $a3 = Code->new(id1 => 1, id2 => 5, id3 => 6, db => $db_pg)->load;
  is($a3->name, 'Thr', 'multi-pk mysql -> pg');

  # mysql -> pg with schema
  $a3->db($db_ws);
  $a3->save(insert => 1);
  $a3 = Code->new(id1 => 1, id2 => 5, id3 => 6, db => $db_ws)->load;
  is($a3->name, 'Thr', 'multi-pk mysql -> pg with schema');
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
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
      $dbh->do('DROP TABLE rdbo_codes CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_codes CASCADE');
      $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums
(
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(32) UNIQUE,
  artist    VARCHAR(32),
  year      INTEGER,
  dt        TIMESTAMP
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_albums
(
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(32) UNIQUE,
  artist    VARCHAR(32),
  year      INTEGER,
  dt        TIMESTAMP
)
EOF

    $dbh->do('CREATE SEQUENCE Rose_db_object_private.rdbo_seq');

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_codes
(
  id1       SERIAL NOT NULL,
  id2       INT NOT NULL,
  id3       INT  NOT NULL DEFAULT nextval('Rose_db_object_private.rdbo_seq'),
  name      VARCHAR(32) UNIQUE,

  PRIMARY KEY(id1, id2, id3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_codes
(
  id1       SERIAL NOT NULL,
  id2       INT NOT NULL,
  id3       INT  NOT NULL DEFAULT nextval('Rose_db_object_private.rdbo_seq'),
  name      VARCHAR(32) UNIQUE,

  PRIMARY KEY(id1, id2, id3)
)
EOF

    $dbh->disconnect;

    Rose::DB->default_type('pg');

    package Album;
    our @ISA = qw(Rose::DB::Object);
    Album->meta->table('rdbo_albums');
    Album->meta->auto_initialize;

    package AlbumWS;
    our @ISA = qw(Rose::DB::Object);
    AlbumWS->meta->table('rdbo_albums');
    AlbumWS->meta->schema('Rose_db_object_private');
    AlbumWS->meta->auto_initialize;

    package Code;
    our @ISA = qw(Rose::DB::Object);
    Code->meta->table('rdbo_codes');
    Code->meta->auto_initialize;
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
    $Have{'mysql'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
      $dbh->do('DROP TABLE rdbo_codes CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums
(
  id        INT PRIMARY KEY AUTO_INCREMENT,
  name      VARCHAR(32) UNIQUE,
  artist    VARCHAR(32),
  year      INTEGER,
  dt        TIMESTAMP
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_codes
(
  id1       INT NOT NULL AUTO_INCREMENT,
  id2       INT NOT NULL,
  id3       INT NOT NULL,
  name      VARCHAR(32) UNIQUE,

  PRIMARY KEY(id1, id2, id3)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
    $dbh->do('DROP TABLE rdbo_albums CASCADE');
    $dbh->do('DROP TABLE rdbo_codes CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_codes CASCADE');
    $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq CASCADE');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_albums CASCADE');
    $dbh->do('DROP TABLE rdbo_codes CASCADE');

    $dbh->disconnect;
  }
}
