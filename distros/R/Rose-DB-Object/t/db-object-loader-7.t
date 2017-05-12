#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (5 * 20);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

our @Tables = qw(vendor product price color product_color_map);
our $Include_Tables = join('|', @Tables);

SETUP:
{
  package My::DB;
  our @ISA = qw(Rose::DB);

  package My::DB::Object::Metadata;
  our @ISA = qw(Rose::DB::Object::Metadata);    
  sub make_column_methods
  {
    my($self) = shift;
    $JCS::Called_For{$self->class}++;
    $self->SUPER::make_column_methods(@_);
  }

  package My::DB::Object;
  our @ISA = qw(Rose::DB::Object);
  sub meta_class { 'My::DB::Object::Metadata' }
  sub foo_bar { 123 }

  package MyWeirdClass;
  our @ISA = qw(Rose::Object);
  sub baz { 456 }
}

#
# Tests
#

# We'll need to clear the registry since we're using DSN instead
our $real_registry  = Rose::DB->registry;
our $empty_registry = Rose::DB::Registry->new;

my $i = 1;

foreach my $db_type (qw(mysql pg_with_schema pg informix sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 20)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  $i++;

  Rose::DB->registry($real_registry);
  Rose::DB::Object::Metadata->unregister_all_classes;

  my $class_prefix = ucfirst($db_type eq 'pg_with_schema' ? 'pgws' : $db_type);

  #$Rose::DB::Object::Metadata::Debug = 1;

  my $db = My::DB->new($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db_dsn       => $db->dsn,
      db_schema    => $db->schema,
      db_username  => $db->username,
      db_password  => $db->password,
      base_classes => [ qw(My::DB::Object MyWeirdClass) ],
      class_prefix => $class_prefix);

  # XXX: This is the important part of this test
  $loader->convention_manager->tables_are_singular(1);

  Rose::DB->registry($empty_registry);

  my @classes = $loader->make_classes(include_tables => $Include_Tables);

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition if($class->can('meta'));
  #}

  my $product_class = $class_prefix . '::Product';

  no warnings qw(redefine once);
  *My::DB::Object::init_db = sub { $db };

  if($db_type =~ /^pg/)
  {
    is($product_class->meta->column('name_fk')->default, undef, "null default fk - $db_type");
    is($product_class->meta->column('some_text')->type, 'text', "text column - $db_type");
  }
  else
  {
    SKIP: { skip("null default fk - $db_type", 1) }
    SKIP: { skip("text column - $db_type", 1) }
  }

  ok($JCS::Called_For{$product_class}, "custom metadata - $db_type");

  ##
  ## Run tests
  ##

  my $p = $product_class->new(name => "Sled $i");

  #ok($p->db->class =~ /^${class_prefix}::DB::AutoBase\d+$/, "db 1 - $db_type");

  ok($p->isa('My::DB::Object'), "base class 1 - $db_type");
  ok($p->isa('MyWeirdClass'), "base class 2 - $db_type");
  is($p->foo_bar, 123, "foo_bar 1 - $db_type");
  is($p->baz, 456, "baz 1 - $db_type");

  if($db_type eq 'pg_with_schema')
  {
    is($p->db->schema, lc 'Rose_db_object_private', "schema - $db_type");
  }
  else
  {
    ok(1, "schema - $db_type");
  }

  $p->vendor(name => "Acme $i");

  $p->prices({ price => 1.25, region => 'US' },
             { price => 4.25, region => 'UK' });

  $p->colors({ name => 'red'   }, 
             { name => 'green' });

  $p->save;

  $p = $product_class->new(id => $p->id)->load;
  is($p->vendor->name, "Acme $i", "vendor 1 - $db_type");


  my @prices = sort { $a->price <=> $b->price } $p->prices;

  is(scalar @prices, 2, "prices 1 - $db_type");
  is($prices[0]->price, 1.25, "prices 2 - $db_type");
  is($prices[1]->price, 4.25, "prices 3 - $db_type");

  my @colors = sort { $a->name cmp $b->name } $p->colors;

  is(scalar @colors, 2, "colors 1 - $db_type");
  is($colors[0]->name, 'green', "colors 2 - $db_type");
  is($colors[1]->name, 'red', "colors 3 - $db_type");

  my $mgr_class = $class_prefix . '::Product::Manager';
  my $prods = $mgr_class->get_products(query => [ id => $p->id ]);

  is(ref $prods, 'ARRAY', "get_products 1 - $db_type");
  is(@$prods, 1, "get_products 2 - $db_type");
  is($prods->[0]->id, $p->id, "get_products 3 - $db_type");

  if($db_type eq 'pg')
  {
    # Check for float bug fixed in 0.761
    $prods->[0]->num(37.3053); # dies with "value too long" in <0.761
  }

  SKIP:
  {
    skip('MySQL tests', 2)  if($db_type ne 'mysql');

    is($product_class->meta->column('smint')->type, 'integer', "small int - $db_type");
    is($product_class->meta->column('medint')->type, 'integer', "medium int - $db_type");
  }

  #$DB::single = 1;
  #$Rose::DB::Object::Debug = 1;
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

      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE color CASCADE');
      $dbh->do('DROP TABLE price CASCADE');
      $dbh->do('DROP TABLE product CASCADE');
      $dbh->do('DROP TABLE vendor CASCADE');

      $dbh->do('DROP TABLE Rose_db_object_private.product_color_map CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.color CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.price CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.product CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.vendor CASCADE');

      $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE vendor
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  vendor_id  INT REFERENCES vendor (id),

  name_fk VARCHAR(255) REFERENCES product (name),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  num     float(4),

  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date  TIMESTAMP,

  some_text  TEXT,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE price
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES product (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE color
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES product (id),
  color_id    INT NOT NULL REFERENCES color (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.vendor
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.product
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  vendor_id  INT REFERENCES Rose_db_object_private.vendor (id),

  name_fk VARCHAR(255) DEFAULT NULL REFERENCES product (name),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  num     float(4),

  date_created  TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date  TIMESTAMP,

  some_text  TEXT,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.price
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES Rose_db_object_private.product (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.color
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.product_color_map
(
  product_id  INT NOT NULL REFERENCES Rose_db_object_private.product (id),
  color_id    INT NOT NULL REFERENCES Rose_db_object_private.color (id),

  PRIMARY KEY(product_id, color_id)
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

    die "MySQL version too old"  unless($db->database_version >= 4_000_000);

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE color CASCADE');
      $dbh->do('DROP TABLE price CASCADE');
      $dbh->do('DROP TABLE product CASCADE');
      $dbh->do('DROP TABLE vendor CASCADE');
    }

    # Foreign key stuff requires InnoDB support
    $dbh->do(<<"EOF");
CREATE TABLE vendor
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
    $sth->execute('vendor');
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
CREATE TABLE product
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  smint   SMALLINT,
  medint  MEDIUMINT,

  vendor_id  INT,

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  TIMESTAMP,
  release_date  TIMESTAMP,

  UNIQUE(name),
  INDEX(vendor_id),

  FOREIGN KEY (vendor_id) REFERENCES vendor (id) ON DELETE NO ACTION ON UPDATE SET NULL
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE price
(
  id          INT AUTO_INCREMENT PRIMARY KEY,
  product_id  INT NOT NULL,
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES product (id)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE color
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL,
  color_id    INT NOT NULL,

  PRIMARY KEY(product_id, color_id),

  INDEX(color_id),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES product (id),
  FOREIGN KEY (color_id) REFERENCES color (id)
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

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE product_color_map CASCADE');
      $dbh->do('DROP TABLE color CASCADE');
      $dbh->do('DROP TABLE price CASCADE');
      $dbh->do('DROP TABLE product CASCADE');
      $dbh->do('DROP TABLE vendor CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE vendor
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES vendor (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME YEAR TO SECOND,
  release_date  DATETIME YEAR TO SECOND,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE price
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES product (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE color
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES product (id),
  color_id    INT NOT NULL REFERENCES color (id),

  PRIMARY KEY(product_id, color_id)
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

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE product_color_map');
      $dbh->do('DROP TABLE color');
      $dbh->do('DROP TABLE price');
      $dbh->do('DROP TABLE product');
      $dbh->do('DROP TABLE vendor');
    }

    $dbh->do(<<"EOF");
CREATE TABLE vendor
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product
(
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES vendor (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME,
  release_date  DATETIME,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE price
(
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INT NOT NULL REFERENCES product (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE color
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE product_color_map
(
  product_id  INT NOT NULL REFERENCES product (id),
  color_id    INT NOT NULL REFERENCES color (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test table

  Rose::DB->registry($real_registry);

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE color CASCADE');
    $dbh->do('DROP TABLE price CASCADE');
    $dbh->do('DROP TABLE product CASCADE');
    $dbh->do('DROP TABLE vendor CASCADE');

    $dbh->do('DROP TABLE Rose_db_object_private.product_color_map CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.color CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.price CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.product CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.vendor CASCADE');

    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE color CASCADE');
    $dbh->do('DROP TABLE price CASCADE');
    $dbh->do('DROP TABLE product CASCADE');
    $dbh->do('DROP TABLE vendor CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map CASCADE');
    $dbh->do('DROP TABLE color CASCADE');
    $dbh->do('DROP TABLE price CASCADE');
    $dbh->do('DROP TABLE product CASCADE');
    $dbh->do('DROP TABLE vendor CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE product_color_map');
    $dbh->do('DROP TABLE color');
    $dbh->do('DROP TABLE price');
    $dbh->do('DROP TABLE product');
    $dbh->do('DROP TABLE vendor');

    $dbh->disconnect;
  }
}
