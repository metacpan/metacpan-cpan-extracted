#!/usr/bin/perl -w

use strict;

use Test::More tests => 32;

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
    skip("$db_type tests", 6)  unless($HAVE{$db_type});
  }

  next  unless($HAVE{$db_type});

  Rose::DB->default_type($db_type);

  unless($DID_SETUP++)
  {
    # Load classes
    use FindBin qw($Bin);
    use lib "$Bin/lib";
    require My::DB::Gene::Main;
    require My::DB::Unigene::Main;
  }

  # Run tests

  is(join(', ', map { $_->name } My::DB::Gene2Unigene->meta->foreign_keys),
     'Rose_db_object_g_main, Rose_db_object_ug_main', "foreign_keys 1 - $db_type");  

  is(join(', ', map { $_->name . ' ' . $_->type} My::DB::Gene::Main->meta->relationships),
     'unigenes many to many', "relationships 1 - $db_type");

  is(join(', ', map { $_->name . ' ' . $_->type} My::DB::Unigene::Main->meta->relationships),
     'genes many to many', "relationships 2 - $db_type");

  is(scalar @Rose::DB::Object::Metadata::Deferred_Relationships || 0, 0,
     "deferred relationships - $db_type");

  # XXX: switch entirely to per-db SQL?
  #My::DB::Gene::Main->meta->init_with_db(Rose::DB->new);
  #My::DB::Unigene::Main->meta->init_with_db(Rose::DB->new);

  my $g = My::DB::Gene::Main->new;
  eval { $g->unigenes };
  ok(!$@, "unigenes - $db_type");

  $g = My::DB::Unigene::Main->new;
  eval { $g->genes };
  ok(!$@, "genes - $db_type");
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
      $dbh->do('DROP TABLE Rose_db_object_g_ug CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_ug_main CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_g_main CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_g_ug CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_ug_main CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_g_main CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_ug_main
(
  ug_id         VARCHAR PRIMARY KEY NOT NULL,
  species       VARCHAR,
  symbol        VARCHAR,
  description   VARCHAR,
  cytoband      VARCHAR,
  scount        INTEGER,
  homol         VARCHAR,
  rest_expr     VARCHAR,
  mgi           VARCHAR
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_main
(
  tax_id           INTEGER,
  gene_id          INTEGER PRIMARY KEY,
  symbol           VARCHAR,
  locustag         VARCHAR,
  chromosome       VARCHAR,
  map_location     VARCHAR,
  description      VARCHAR,
  gene_type        VARCHAR,
  symbol_from_nomenclature_auth    VARCHAR,
  full_name_from_nomenclature_auth VARCHAR,
  nomenclature_status              VARCHAR,
  discontinued     BOOLEAN DEFAULT FALSE,
  new_gene_id      INTEGER DEFAULT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_ug
(
  g_ug_id SERIAL PRIMARY KEY,

  gene_id INTEGER REFERENCES Rose_db_object_g_main (gene_id) 
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,

  ug_id VARCHAR REFERENCES Rose_db_object_ug_main (ug_id) 
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_ug_main
(
  ug_id         VARCHAR PRIMARY KEY NOT NULL,
  species       VARCHAR,
  symbol        VARCHAR,
  description   VARCHAR,
  cytoband      VARCHAR,
  scount        INTEGER,
  homol         VARCHAR,
  rest_expr     VARCHAR,
  mgi           VARCHAR
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_g_main
(
  tax_id           INTEGER,
  gene_id          INTEGER PRIMARY KEY,
  symbol           VARCHAR,
  locustag         VARCHAR,
  chromosome       VARCHAR,
  map_location     VARCHAR,
  description      VARCHAR,
  gene_type        VARCHAR,
  symbol_from_nomenclature_auth    VARCHAR,
  full_name_from_nomenclature_auth VARCHAR,
  nomenclature_status              VARCHAR,
  discontinued     BOOLEAN DEFAULT FALSE,
  new_gene_id      INTEGER DEFAULT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_g_ug
(
  g_ug_id SERIAL PRIMARY KEY,

  gene_id INTEGER REFERENCES Rose_db_object_private.Rose_db_object_g_main (gene_id) 
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,

  ug_id VARCHAR REFERENCES Rose_db_object_private.Rose_db_object_ug_main (ug_id) 
    ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE
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
      $dbh->do('DROP TABLE Rose_db_object_g_ug CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_ug_main CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_g_main CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_ug_main
(
  ug_id         VARCHAR(255) NOT NULL PRIMARY KEY,
  species       VARCHAR(255),
  symbol        VARCHAR(255),
  description   VARCHAR(255),
  cytoband      VARCHAR(255),
  scount        INT,
  homol         VARCHAR(255),
  rest_expr     VARCHAR(255),
  mgi           VARCHAR(255)
)
ENGINE=InnoDB
EOF
  };

  if(!$@ && $dbh)
  {
    $HAVE{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_main
(
  gene_id          INT NOT NULL PRIMARY KEY,
  tax_id           INT,
  symbol           VARCHAR(255),
  locustag         VARCHAR(255),
  chromosome       VARCHAR(255),
  map_location     VARCHAR(255),
  description      VARCHAR(255),
  gene_type        VARCHAR(255),
  symbol_from_nomenclature_auth    VARCHAR(255),
  full_name_from_nomenclature_auth VARCHAR(255),
  nomenclature_status              VARCHAR(255),
  discontinued     INT DEFAULT 0,
  new_gene_id      INT DEFAULT NULL
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_ug
(
  g_ug_id  INT PRIMARY KEY,
  gene_id  INT NOT NULL,
  ug_id    VARCHAR(255) NOT NULL,

  INDEX(gene_id),
  INDEX(ug_id),

  FOREIGN KEY (gene_id) REFERENCES Rose_db_object_g_main (gene_id),
  FOREIGN KEY (ug_id) REFERENCES Rose_db_object_ug_main (ug_id)
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
    $HAVE{'informix'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_g_ug');
      $dbh->do('DROP TABLE Rose_db_object_ug_main');
      $dbh->do('DROP TABLE Rose_db_object_g_main');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_ug_main
(
  ug_id         VARCHAR(255) NOT NULL PRIMARY KEY,
  species       VARCHAR(255),
  symbol        VARCHAR(255),
  description   VARCHAR(255),
  cytoband      VARCHAR(255),
  scount        INT,
  homol         VARCHAR(255),
  rest_expr     VARCHAR(255),
  mgi           VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_main
(
  tax_id           INT,
  gene_id          INT PRIMARY KEY,
  symbol           VARCHAR(255),
  locustag         VARCHAR(255),
  chromosome       VARCHAR(255),
  map_location     VARCHAR(255),
  description      VARCHAR(255),
  gene_type        VARCHAR(255),
  symbol_from_nomenclature_auth    VARCHAR(255),
  full_name_from_nomenclature_auth VARCHAR(255),
  nomenclature_status              VARCHAR(255),
  discontinued     INT DEFAULT 0,
  new_gene_id      INT DEFAULT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_ug
(
  g_ug_id  SERIAL PRIMARY KEY,
  gene_id  INT REFERENCES Rose_db_object_g_main (gene_id),
  ug_id    VARCHAR(255) REFERENCES Rose_db_object_ug_main (ug_id) 
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
      $dbh->do('DROP TABLE Rose_db_object_g_ug');
      $dbh->do('DROP TABLE Rose_db_object_ug_main');
      $dbh->do('DROP TABLE Rose_db_object_g_main');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_ug_main
(
  ug_id         VARCHAR(255) NOT NULL PRIMARY KEY,
  species       VARCHAR(255),
  symbol        VARCHAR(255),
  description   VARCHAR(255),
  cytoband      VARCHAR(255),
  scount        INT,
  homol         VARCHAR(255),
  rest_expr     VARCHAR(255),
  mgi           VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_main
(
  tax_id           INT,
  gene_id          INT PRIMARY KEY,
  symbol           VARCHAR(255),
  locustag         VARCHAR(255),
  chromosome       VARCHAR(255),
  map_location     VARCHAR(255),
  description      VARCHAR(255),
  gene_type        VARCHAR(255),
  symbol_from_nomenclature_auth    VARCHAR(255),
  full_name_from_nomenclature_auth VARCHAR(255),
  nomenclature_status              VARCHAR(255),
  discontinued     INT DEFAULT 0,
  new_gene_id      INT DEFAULT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_g_ug
(
  g_ug_id  INTEGER PRIMARY KEY AUTOINCREMENT,
  gene_id  INTEGER REFERENCES Rose_db_object_g_main (gene_id),
  ug_id    VARCHAR(255) REFERENCES Rose_db_object_ug_main (ug_id) 
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

    $dbh->do('DROP TABLE Rose_db_object_g_ug CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_ug_main CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_g_main CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_g_ug CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_ug_main CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_g_main CASCADE');

    $dbh->disconnect;
  }

  if($HAVE{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_g_ug CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_ug_main CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_g_main CASCADE');

    $dbh->disconnect;
  }

  if($HAVE{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_g_ug CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_ug_main CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_g_main CASCADE');

    $dbh->disconnect;
  }

  if($HAVE{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_g_ug');
    $dbh->do('DROP TABLE Rose_db_object_ug_main');
    $dbh->do('DROP TABLE Rose_db_object_g_main');

    $dbh->disconnect;
  }
}
