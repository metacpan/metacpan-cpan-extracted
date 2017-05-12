#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;

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

foreach my $db_type (qw(mysql pg pg_with_schema informix sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 2)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix = 
    ucfirst($db_type eq 'pg_with_schema' ? 'pgws' : $db_type) . 'MusicDB';

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => 'rdbo_album.*');

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition(braces => 'k&r', indent => 2)
  #    if($class->can('meta'));
  #}

  my $manager_class = $class_prefix . '::RdboAlbumArtwork::Manager';

  my $results = 
    $manager_class->get_rdbo_album_artwork(
      query   => [ art_filename => 'album1.jpg' ],
      sort_by => 'art_filename');

  foreach my $res (@$results) 
  {
    my $album = $res->album;
    is($album->name, 'album1', "album 1 - $db_type");
  }

  LEAK_TEST:
  {
    $RDBO::LeakTest = 0;

    my $db_class = ref(Rose::DB->new);

    no strict 'refs';
    no warnings 'redefine';
    *{"${db_class}::DESTROY"} = sub
    {
      $_[0]->disconnect;
      $RDBO::LeakTest++;
    };

    INNER:
    {
      my $iter = 
        $manager_class->get_rdbo_album_artwork_iterator(
          query   => [ art_filename => 'album1.jpg' ],
          sort_by => 'art_filename');

      while(my $res = $iter->next)
      {
        # do nothing
      }
    }

    ok($RDBO::LeakTest > 0, "iterator db leak check - $db_type");
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
      $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_album_artwork CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums 
(
  id        INTEGER PRIMARY KEY,
  other_id  VARCHAR(32) UNIQUE,
  name      VARCHAR(32),
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_album_artwork 
(
  art_filename   VARCHAR(32) PRIMARY KEY,
  album_other_id VARCHAR(32) REFERENCES rdbo_albums (other_id)
)
EOF

    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (1, 'id1', 'album1', 'artist1', 1999)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (2, 'id2', 'album2', 'artist1', 2000)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (3, 'id3', 'album3', 'artist2', 1934)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (4, 'id4', 'album4', 'artist2', 2020)));

    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album1.jpg', 'id1')));
    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album2.jpg', 'id2')));

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_albums 
(
  id        INTEGER PRIMARY KEY,
  other_id  VARCHAR(32) UNIQUE,
  name      VARCHAR(32),
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_album_artwork 
(
  art_filename   VARCHAR(32) PRIMARY KEY,
  album_other_id VARCHAR(32) REFERENCES Rose_db_object_private.rdbo_albums (other_id)
)
EOF

    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_albums VALUES (1, 'id1', 'album1', 'artist1', 1999)));
    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_albums VALUES (2, 'id2', 'album2', 'artist1', 2000)));
    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_albums VALUES (3, 'id3', 'album3', 'artist2', 1934)));
    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_albums VALUES (4, 'id4', 'album4', 'artist2', 2020)));

    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_album_artwork VALUES ('album1.jpg', 'id1')));
    $dbh->do(qq(INSERT INTO Rose_db_object_private.rdbo_album_artwork VALUES ('album2.jpg', 'id2')));

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    die "MySQL version too old"  unless($db->database_version >= 4_000_000);

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums 
(
  id        INTEGER PRIMARY KEY,
  other_id  VARCHAR(32) UNIQUE,
  name      VARCHAR(32),
  artist    VARCHAR(32),
  year      INTEGER
)
ENGINE=InnoDB
EOF

    # MySQL will silently ignore the "ENGINE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('rdbo_albums');
    my $info = $sth->fetchrow_hashref;

    no warnings 'uninitialized';
    unless(lc $info->{'Type'} eq 'innodb' || lc $info->{'Engine'} eq 'innodb')
    {
      die "Missing InnoDB support";
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_album_artwork 
(
  art_filename   VARCHAR(32) PRIMARY KEY,
  album_other_id VARCHAR(32),

  INDEX(album_other_id),

  FOREIGN KEY (album_other_id) REFERENCES rdbo_albums (other_id)
)
ENGINE=InnoDB
EOF

    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (1, 'id1', 'album1', 'artist1', 1999)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (2, 'id2', 'album2', 'artist1', 2000)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (3, 'id3', 'album3', 'artist2', 1934)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (4, 'id4', 'album4', 'artist2', 2020)));

    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album1.jpg', 'id1')));
    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album2.jpg', 'id2')));

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
      $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums 
(
  id        INTEGER PRIMARY KEY,
  other_id  VARCHAR(32) UNIQUE,
  name      VARCHAR(32),
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_album_artwork 
(
  art_filename   VARCHAR(32) PRIMARY KEY,
  album_other_id VARCHAR(32) REFERENCES rdbo_albums (other_id)
)
EOF

    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (1, 'id1', 'album1', 'artist1', 1999)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (2, 'id2', 'album2', 'artist1', 2000)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (3, 'id3', 'album3', 'artist2', 1934)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (4, 'id4', 'album4', 'artist2', 2020)));

    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album1.jpg', 'id1')));
    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album2.jpg', 'id2')));

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
      $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
      $dbh->do('DROP TABLE rdbo_albums CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_albums 
(
  id        INTEGER PRIMARY KEY,
  other_id  VARCHAR(32) UNIQUE,
  name      VARCHAR(32),
  artist    VARCHAR(32),
  year      INTEGER
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_album_artwork 
(
  art_filename   VARCHAR(32) PRIMARY KEY,
  album_other_id VARCHAR(32) REFERENCES rdbo_albums (other_id)
)
EOF

    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (1, 'id1', 'album1', 'artist1', 1999)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (2, 'id2', 'album2', 'artist1', 2000)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (3, 'id3', 'album3', 'artist2', 1934)));
    $dbh->do(qq(INSERT INTO rdbo_albums VALUES (4, 'id4', 'album4', 'artist2', 2020)));

    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album1.jpg', 'id1')));
    $dbh->do(qq(INSERT INTO rdbo_album_artwork VALUES ('album2.jpg', 'id2')));

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

    $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
    $dbh->do('DROP TABLE rdbo_albums CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_album_artwork CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_albums CASCADE');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
    $dbh->do('DROP TABLE rdbo_albums CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_album_artwork CASCADE');
    $dbh->do('DROP TABLE rdbo_albums CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_album_artwork');
    $dbh->do('DROP TABLE rdbo_albums');

    $dbh->disconnect;
  }
}
