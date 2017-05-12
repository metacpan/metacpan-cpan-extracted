#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our $HAVE_PG;

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 6)  unless($HAVE_PG);

  OVERRIDE_OK:
  {
    no warnings;
    *MyPgObject::init_db = sub {  Rose::DB->new($db_type) };
  }

  my $o = MyPgObject->new(name => 'John', 
                          k1   => 1,
                          k2   => undef,
                          k3   => 3);

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('TRUE');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");

  is($o->id, 1, "auto-generated primary key - $db_type");
}

BEGIN
{
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
    our $HAVE_PG = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_chkpass_test');
      $dbh->do('DROP SEQUENCE Rose_db_object_test_seq');
      $dbh->do('DROP SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do('CREATE SEQUENCE Rose_db_object_test_seq');

    my $pg_vers = $dbh->{'pg_server_version'};    
    my $active = $pg_vers >= 80100 ? q('act''ive') : q('act\'ive');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT DEFAULT nextval('Rose_db_object_test_seq') NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL DEFAULT 't',
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT $active,
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(save),
  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do('CREATE SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test
(
  id             INT DEFAULT nextval('Rose_db_object_test_seq') NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL DEFAULT 't',
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT $active,
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(save),
  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->disconnect;

    Rose::DB->default_type('pg');

    package MyTmpPgObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyTmpPgObject->meta->table('Rose_db_object_test');

    MyTmpPgObject->meta->auto_initialize;

    my $code = MyTmpPgObject->meta->perl_class_definition;
    $code =~ s/\bMyTmpPgObject\b/MyPgObject/g;

    eval $code;
    die $@  if($@);
  }
}

END
{
  # Delete test table

  if($HAVE_PG)
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
    $dbh->do('DROP SEQUENCE Rose_db_object_test_seq');
    $dbh->do('DROP SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }
}
