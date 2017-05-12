#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (6 * 2);

BEGIN
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

our @Tables = sort qw(rdbo_test_vendors rdbo_test_products rdbo_test_prices
                      rdbo_test_colors rdbo_test_products_colors);
my $Regex = '^(?:' . join('|', @Tables, 'rdbo_test_view', 'read') . ')';

our %Have;

#
# Tests
#

foreach my $db_type (qw(mysql pg pg_with_schema informix sqlite oracle))
{
  SKIP:
  {
    unless($Have{$db_type})
    {
      skip("$db_type tests", 2);
    }
  }

  next  unless($Have{$db_type});

  My::DB2->default_type($db_type);

  my $db = My::DB2->new;

  # Oracle returns names in upper case.
  my @tables = sort grep { /$Regex/i } $db->list_tables;

  if($db_type eq 'mysql')
  {
    is_deeply(\@tables, [ sort(@Tables, 'read') ], "$db_type tables 1");
  }
  elsif($db_type eq 'informix')
  {
    # Informix shows views every time
    is_deeply(\@tables, [ sort(@Tables, 'rdbo_test_view') ], "$db_type tables");
  }
  elsif($db_type eq 'oracle')
  {
    is_deeply(\@tables, [ map { uc } @Tables ], "$db_type tables 1");
  }
  else
  {
    is_deeply(\@tables, \@Tables, "$db_type tables 1");
  }

  # Oracle returns names in upper case.
  @tables = sort grep { /$Regex/i } $db->list_tables(include_views => 1);

  if($db_type =~ /^(?:pg(?:_with_schema)?|sqlite|informix)$/)
  {
    is_deeply(\@tables, [ sort(@Tables, 'rdbo_test_view') ], "$db_type tables and views");
  }
  else
  {
    if($db_type eq 'mysql')
    {
      is_deeply(\@tables, [ sort(@Tables, 'read') ], "$db_type tables and views");
    }
    elsif($db_type eq 'oracle')
    {
      is_deeply(\@tables, [ map { uc } (@Tables, 'rdbo_test_view') ], "$db_type tables and views");
    }
    else
    {
      is_deeply(\@tables, \@Tables, "$db_type tables and views");
    }
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
    $dbh = My::DB2->new('pg_admin')->retain_dbh()
      or die My::DB2->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP VIEW rdbo_test_view');
      $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
      $dbh->do('DROP TABLE rdbo_test_products CASCADE');
      $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');

      $dbh->do('DROP VIEW Rose_db_object_private.rdbo_test_view');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_products_colors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_colors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_prices CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_products CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_vendors CASCADE');

      $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  vendor_id  INT REFERENCES rdbo_test_vendors (id),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive'
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date  TIMESTAMP,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products_colors
(
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  color_id    INT NOT NULL REFERENCES rdbo_test_colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE VIEW rdbo_test_view AS SELECT * FROM rdbo_test_colors
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_test_vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_test_products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  vendor_id  INT REFERENCES rdbo_test_vendors (id),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive'
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date  TIMESTAMP,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_test_prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_test_colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.rdbo_test_products_colors
(
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  color_id    INT NOT NULL REFERENCES rdbo_test_colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE VIEW Rose_db_object_private.rdbo_test_view AS
  SELECT * FROM Rose_db_object_private.rdbo_test_colors
EOF

    $dbh->disconnect;
  }

  #
  # Oracle
  #

  eval
  {
    $dbh = My::DB2->new('oracle_admin')->retain_dbh()
      or die My::DB2->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'oracle'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP VIEW rdbo_test_view');
      $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rdbo_test_colors CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rdbo_test_prices CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rdbo_test_products CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rdbo_test_vendors CASCADE CONSTRAINTS');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_vendors
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products
(
  id      INT NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES rdbo_test_vendors (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATE,
  release_date  DATE,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_prices
(
  id          INT NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_colors
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products_colors
(
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  color_id    INT NOT NULL REFERENCES rdbo_test_colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE VIEW rdbo_test_view AS SELECT * FROM rdbo_test_colors
EOF

    $dbh->commit;
    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval
  {
    my $db = My::DB2->new('mysql_admin');
    $dbh = $db->retain_dbh or die My::DB2->error;

    die "MySQL version too old"  unless($db->database_version >= 4_000_000);

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
      $dbh->do('DROP TABLE rdbo_test_products CASCADE');
      $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');
      $dbh->do('DROP TABLE `read` CASCADE');
    }

    # Foreign key stuff requires InnoDB support
    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_vendors
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    # MySQL will silently ignore the "ENGINE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('rdbo_test_vendors');
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
CREATE TABLE rdbo_test_products
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  vendor_id  INT,

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive'
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME,
  release_date  DATETIME,

  UNIQUE(name),
  INDEX(vendor_id),

  FOREIGN KEY (vendor_id) REFERENCES rdbo_test_vendors (id) ON DELETE NO ACTION ON UPDATE SET NULL
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_prices
(
  id          INT AUTO_INCREMENT PRIMARY KEY,
  product_id  INT NOT NULL,
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES rdbo_test_products (id) ON UPDATE NO ACTION
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_colors
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products_colors
(
  product_id  INT NOT NULL,
  color_id    INT NOT NULL,

  PRIMARY KEY(product_id, color_id),

  INDEX(color_id),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES rdbo_test_products (id) ON DELETE RESTRICT,
  FOREIGN KEY (color_id) REFERENCES rdbo_test_colors (id) ON UPDATE NO ACTION
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE `read`
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  `read`  VARCHAR(255) NOT NULL
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
    $dbh = My::DB2->new('informix_admin')->retain_dbh()
      or die My::DB2->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'informix'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP VIEW rdbo_test_view');
      $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
      $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
      $dbh->do('DROP TABLE rdbo_test_products CASCADE');
      $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES rdbo_test_vendors (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME YEAR TO SECOND,
  release_date  DATETIME YEAR TO SECOND,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products_colors
(
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  color_id    INT NOT NULL REFERENCES rdbo_test_colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE VIEW rdbo_test_view AS SELECT * FROM rdbo_test_colors
EOF

    #$dbh->commit;
    $dbh->disconnect;
  }

  #
  # SQLite
  #

  eval
  {
    $dbh = My::DB2->new('sqlite_admin')->retain_dbh()
      or die My::DB2->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'sqlite'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP VIEW rdbo_test_view');
      $dbh->do('DROP TABLE rdbo_test_products_colors');
      $dbh->do('DROP TABLE rdbo_test_colors');
      $dbh->do('DROP TABLE rdbo_test_prices');
      $dbh->do('DROP TABLE rdbo_test_products');
      $dbh->do('DROP TABLE rdbo_test_vendors');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_vendors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products
(
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES rdbo_test_vendors (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME,
  release_date  DATETIME,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_prices
(
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_colors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_test_products_colors
(
  product_id  INT NOT NULL REFERENCES rdbo_test_products (id),
  color_id    INT NOT NULL REFERENCES rdbo_test_colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE VIEW rdbo_test_view AS SELECT * FROM rdbo_test_colors
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
    my $dbh = My::DB2->new('pg_admin')->retain_dbh()
      or die My::DB2->error;

    $dbh->do('DROP VIEW rdbo_test_view');
    $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
    $dbh->do('DROP TABLE rdbo_test_products CASCADE');
    $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');

    $dbh->do('DROP VIEW Rose_db_object_private.rdbo_test_view');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_products_colors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_colors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_prices CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_products CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.rdbo_test_vendors CASCADE');

    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'oracle'})
  {
    # Oracle
    my $dbh = My::DB2->new('oracle_admin')->retain_dbh()
      or die My::DB2->error;

    $dbh->do('DROP VIEW rdbo_test_view');
    $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rdbo_test_colors CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rdbo_test_prices CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rdbo_test_products CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rdbo_test_vendors CASCADE CONSTRAINTS');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = My::DB2->new('mysql_admin')->retain_dbh()
      or die My::DB2->error;

    $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
    $dbh->do('DROP TABLE rdbo_test_products CASCADE');
    $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');
    $dbh->do('DROP TABLE `read` CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = My::DB2->new('informix_admin')->retain_dbh()
      or die My::DB2->error;

    $dbh->do('DROP VIEW rdbo_test_view');
    $dbh->do('DROP TABLE rdbo_test_products_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_colors CASCADE');
    $dbh->do('DROP TABLE rdbo_test_prices CASCADE');
    $dbh->do('DROP TABLE rdbo_test_products CASCADE');
    $dbh->do('DROP TABLE rdbo_test_vendors CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = My::DB2->new('sqlite_admin')->retain_dbh()
      or die My::DB2->error;

    $dbh->do('DROP VIEW rdbo_test_view');
    $dbh->do('DROP TABLE rdbo_test_products_colors');
    $dbh->do('DROP TABLE rdbo_test_colors');
    $dbh->do('DROP TABLE rdbo_test_prices');
    $dbh->do('DROP TABLE rdbo_test_products');
    $dbh->do('DROP TABLE rdbo_test_vendors');

    $dbh->disconnect;
  }
}
