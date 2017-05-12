#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (3 * 4);

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
    skip("$db_type tests", 3)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB::Object::Metadata->unregister_all_classes;
  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $foo_class = $class_prefix . '::Foo';
  my $bar_class = $class_prefix . '::Bar';

  my $auto = (rand() >= 0.5) ? 'auto_initialize => [],' : 'auto => 1,';

  my $perl=<<"EOF";
{
  package $foo_class;
  use base qw(Rose::DB::Object);
  __PACKAGE__->meta->setup
  (
    table => 'foos',
    $auto
  );

  package $bar_class;
  use base qw(Rose::DB::Object);
  __PACKAGE__->meta->setup
  (
    table => 'bars',
    $auto
  );
}
EOF

  eval $perl or warn $@;

  is($foo_class->meta->relationship('bar')->type, 'one to one', "check rel type - $db_type");

  my $bar = $bar_class->new;
  my $foo = $foo_class->new(foo => 'xyz');

  #$Rose::DB::Object::Debug = 1;

  $foo->bar($bar);
  $foo->bar->bar('some text');
  $foo->save;

  my $check_foo = $foo_class->new(id => $foo->id)->load;
  my $check_bar = $bar_class->new(foo_id => $bar->foo_id)->load;

  is($check_foo->foo, 'xyz', "check foo - $db_type");
  is($check_bar->bar, 'some text', "check bar - $db_type");
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

      $dbh->do('DROP TABLE bars CASCADE');
      $dbh->do('DROP TABLE foos CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE foos
(
  id   SERIAL NOT NULL PRIMARY KEY, 
  foo  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE bars
(
  foo_id  INT NOT NULL PRIMARY KEY REFERENCES foos (id),
  bar     VARCHAR(255)
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

    die "No innodb support"  unless(mysql_supports_innodb());

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE bars CASCADE');
      $dbh->do('DROP TABLE foos CASCADE');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE foos
(
  id   INT AUTO_INCREMENT PRIMARY KEY, 
  foo  VARCHAR(255)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE bars
(
  foo_id  INT  PRIMARY KEY,
  bar     VARCHAR(255),

  INDEX(foo_id),

  FOREIGN KEY (foo_id) REFERENCES foos (id)
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

      $dbh->do('DROP TABLE bars CASCADE');
      $dbh->do('DROP TABLE foos CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE foos
(
  id   SERIAL NOT NULL PRIMARY KEY, 
  foo  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE bars
(
  foo_id  INT NOT NULL PRIMARY KEY REFERENCES foos (id),
  bar     VARCHAR(255)
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

      $dbh->do('DROP TABLE bars');
      $dbh->do('DROP TABLE foos');
    }

    $dbh->do(<<"EOF");
CREATE TABLE foos
(
  id   INTEGER PRIMARY KEY AUTOINCREMENT, 
  foo  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE bars
(
  foo_id  INTEGER PRIMARY KEY AUTOINCREMENT REFERENCES foos (id),
  bar     VARCHAR(255)
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

    $dbh->do('DROP TABLE bars CASCADE');
    $dbh->do('DROP TABLE foos CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE bars CASCADE');
    $dbh->do('DROP TABLE foos CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE bars CASCADE');
    $dbh->do('DROP TABLE foos CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE bars');
    $dbh->do('DROP TABLE foos');

    $dbh->disconnect;
  }
}
