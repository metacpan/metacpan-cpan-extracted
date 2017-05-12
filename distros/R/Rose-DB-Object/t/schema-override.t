#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

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
  skip("pg tests", 7)  unless($Have{'pg'});

  my $db_pg = Rose::DB->new('pg');
  my $db_ws = Rose::DB->new('pg_with_schema');

  # Albums should take on the schema of the db handle
  my $a1 = Album->new(db => $db_pg, name => 'One', year => 2001)->save;
  my $a2 = Album->new(db => $db_ws, name => 'One', year => 2002)->save;

  is($a1->id, 1, 'flex schema 1');
  is($a2->id, 1, 'flex schema 2');

  # Album photos should NOT take on the schema of the db handle
  my $p1 = AlbumPhoto->new(db => $db_pg, album_id => 1, name => '1.1')->save;
  my $p2 = AlbumPhoto->new(db => $db_ws, album_id => 1, name => '1.2')->save;

  is($p1->id, 1, 'flex schema 1');
  is($p2->id, 2, 'flex schema 2');

  # Make sure both albums read the same album photos table
  is_deeply([ map { $_->name } sort { $a->id <=> $b->id } $a1->album_photos ], 
            [ '1.1', '1.2' ], 'single photos table 1');

  is_deeply([ map { $_->name } sort { $a->id <=> $b->id } $a2->album_photos ], 
            [ '1.1', '1.2' ], 'single photos table 2');

  $a1 = Album->new(id => $a1->id);
  $a1->load(with => 'album_photos');

  is_deeply([ map { $_->name } sort { $a->id <=> $b->id } $a1->album_photos ], 
            [ '1.1', '1.2' ], 'single photos table 3');
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
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_album_photos CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums
(
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(32) UNIQUE,
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_albums
(
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(32) UNIQUE,
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_album_photos
(
  id        SERIAL PRIMARY KEY,
  album_id  INT REFERENCES rdbo_albums (id),
  name      VARCHAR(32)
)
EOF

    $dbh->disconnect;

    Rose::DB->default_type('pg');

    package MyCM;
    our @ISA = qw(Rose::DB::Object::ConventionManager);
    sub auto_relationship_name_one_to_many
    { 
      my($self, $table, $class) = @_;
      return $self->auto_class_to_relationship_name_plural($class);
    }

    package Album;
    our @ISA = qw(Rose::DB::Object);
    Album->meta->convention_manager('MyCM');
    Album->meta->table('rdbo_albums');
    Album->meta->auto_initialize;

    package AlbumPhoto;
    our @ISA = qw(Rose::DB::Object);
    AlbumPhoto->meta->convention_manager('MyCM');
    AlbumPhoto->meta->table('rdbo_album_photos');
    AlbumPhoto->meta->schema('Rose_db_object_private');
    AlbumPhoto->meta->auto_initialize;
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

    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_album_photos CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
    $dbh->do('DROP TABLE rdbo_albums CASCADE');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }
}
