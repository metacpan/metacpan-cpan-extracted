#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More tests => 1 + (1 * 3);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

#
# Tests
#

foreach my $db_type (qw(sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 3)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  my $loader =
    Rose::DB::Object::Loader->new(
      db_class       => 'My::DB::Opa',
      base_classes   => 'My::DB::Opa::Object',
      class_prefix   => "My::ModelDynamic::$db_type",
      include_tables => 'sites',
  );

  my @classes = $loader->make_classes;

  is(join(',', sort @classes), "My::ModelDynamic::${db_type}::Site,My::ModelDynamic::${db_type}::Site::Manager", "make_classes - $db_type");

  is("My::ModelDynamic::${db_type}::Site"->new->dbh, My::DB::Opa->new_or_cached->dbh, "dbh is cached - $db_type");

  is(My::DB::Opa->connection_count, 1, "connection count - $db_type");
}

BEGIN
{
  our %Have;

  #
  # SQLite
  #

  my $dbh;

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

      $dbh->do('DROP TABLE sites');
    }

    $dbh->do(<<"EOF");
CREATE TABLE sites (
  id    INT(10) NOT NULL,
  host  VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (id)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE sites');

    $dbh->disconnect;
  }
}

1;
