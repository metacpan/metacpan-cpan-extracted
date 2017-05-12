#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (12 * 4);

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
    skip("$db_type tests", 12)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix =  ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => '^rose_db_object_(?:artist|album)s$');

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition, "\n"  if($class->can('meta'));
  #}

  my $artist_class = $class_prefix . '::RoseDbObjectArtist';
  my $album_class = $class_prefix . '::RoseDbObjectAlbum';

  # DBD::Informix chokes badly when prepare_cached() is used.
  Rose::DB::Object::Metadata->dbi_prepare_cached($db_type eq 'informix' ? 0 : 1);

  my $albums_method = 'rose_db_object_albums';

  foreach my $cascade (0, 1)
  {
    my @cascade = $cascade ? (cascade => 1) : ();

    my $album = $album_class->new(id => 1, title => 'album1');
    $album->save();

    my $artist = $artist_class->new(id => 1, name => 'Rage');
    $artist->$albums_method($album->id);
    $artist->save(@cascade);

    ok($artist, "$cascade saved artist with albums - $db_type");

    $artist->$albums_method($album->id);
    $artist->save(@cascade);

    ok($artist, "$cascade re-saved artist albums = $db_type");

    $artist = $artist_class->new(id => $artist->id)->load;
    is(scalar @{$artist->$albums_method() ||[]}, 1, "$cascade Check artist albums count - $db_type");
    is($artist->$albums_method()->[0]->id, $album->id, "$cascade Check artist album ids - $db_type");

    my @albums = $artist->$albums_method();
    $artist->$albums_method(@albums);
    $artist->save;
    $artist->$albums_method(@albums);
    $artist->save;

    $artist = $artist_class->new(id => $artist->id)->load;
    is(scalar @{$artist->$albums_method() ||[]}, 1, "$cascade Check artist albums count 2 - $db_type");
    is($artist->$albums_method()->[0]->id, $album->id, "$cascade Check artist album ids 2 - $db_type");

    $artist->delete(cascade => 1);
  }
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
      $dbh->do('DROP TABLE rose_db_object_albums');
      $dbh->do('DROP TABLE rose_db_object_artists');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_artists
(
  id     INT PRIMARY KEY NOT NULL,
  name   VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_albums
(
  id         INT PRIMARY KEY NOT NULL,
  artist_id  INTEGER REFERENCES rose_db_object_artists (id),
  title      VARCHAR(255) NOT NULL
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    die "No InnoDB support"  unless(mysql_supports_innodb());

    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_albums');
      $dbh->do('DROP TABLE rose_db_object_artists');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_artists
(
  id     INT PRIMARY KEY NOT NULL,
  name   VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_albums
(
  id         INT PRIMARY KEY NOT NULL,
  artist_id  INTEGER REFERENCES rose_db_object_artists (id),
  title      VARCHAR(255) NOT NULL,

  INDEX(artist_id),
  FOREIGN KEY (artist_id) REFERENCES rose_db_object_artists (id)  
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

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_albums');
      $dbh->do('DROP TABLE rose_db_object_artists');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_artists
(
  id     INT PRIMARY KEY,
  name   VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_albums
(
  id         INT PRIMARY KEY,
  artist_id  INT REFERENCES rose_db_object_artists (id),
  title      VARCHAR(255) NOT NULL
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
      $dbh->do('DROP TABLE rose_db_object_albums');
      $dbh->do('DROP TABLE rose_db_object_artists');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_artists
(
  id     INT PRIMARY KEY NOT NULL,
  name   VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_albums
(
  id         INT PRIMARY KEY NOT NULL,
  artist_id  INTEGER REFERENCES rose_db_object_artists (id),
  title      VARCHAR(255) NOT NULL
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

    $dbh->do('DROP TABLE rose_db_object_albums');
    $dbh->do('DROP TABLE rose_db_object_artists');
    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_albums');
    $dbh->do('DROP TABLE rose_db_object_artists');
    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_albums CASCADE');
    $dbh->do('DROP TABLE rose_db_object_artists CASCADE');
    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_albums');
    $dbh->do('DROP TABLE rose_db_object_artists');
    $dbh->disconnect;
  }
}
