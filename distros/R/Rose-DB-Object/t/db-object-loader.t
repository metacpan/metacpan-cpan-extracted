#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (6 * 38) + 9;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

our @Tables = qw(vendors products prices colors products_colors);
our $Include_Tables = join('|', @Tables, 'no_pk_test2?');

our %Reserved_Words;

#
# Tests
#

FOO:
{
  package MyCM;

  @MyCM::ISA = qw(Rose::DB::Object::ConventionManager);

  sub auto_foreign_key_name 
  {
    $JCS::Called_Custom_CM{$_[0]->parent->class}++;
    shift->SUPER::auto_foreign_key_name(@_);
  }
}

my $i = 1;

foreach my $db_type (qw(mysql pg pg_with_schema informix sqlite oracle))
{
  SKIP:
  {
    unless($Have{$db_type})
    {
      skip("$db_type tests", 38 + scalar @{$Reserved_Words{$db_type} ||= []});
    }
  }

  next  unless($Have{$db_type});

  $i++;

  Rose::DB->default_type($db_type);
  Rose::DB::Object::Metadata->unregister_all_classes;

  my $class_prefix = ucfirst($db_type eq 'pg_with_schema' ? 'pgws' : $db_type);

  #$Rose::DB::Object::Metadata::Debug = 1;

  %JCS::Called_Custom_CM = ();

  my $pre_init_hook = 0;

  my $db = Rose::DB->new;
  my $loader = 
    Rose::DB::Object::Loader->new(
      db              => $db,
      class_prefix    => $class_prefix,
      ($db_type eq 'mysql' ? (require_primary_key => 0) : ()),
      pre_init_hook   => sub { $pre_init_hook++ });

  my %extra_loader_args;

  if($db_type eq 'sqlite')
  {
    $loader->warn_on_missing_primary_key(0);
    $loader->warn_on_missing_pk(1);
  }
  elsif($db_type eq 'pg')
  {
    $loader->include_predicated_unique_indexes(1);
  }
  elsif($db_type eq 'mysql')
  {
    $loader->warn_on_missing_pk(0);
    $loader->warn_on_missing_primary_key(1);
    $extra_loader_args{'warn_on_missing_pk'} = undef;
    $extra_loader_args{'warn_on_missing_primary_key'} = undef;
  }

  $loader->convention_manager($i % 2 ? 'MyCM' : MyCM->new);

  my @classes;

  my $i = 0;

  # Test aliased parameter conflicts
  foreach my $a (0, 1, undef)
  {
    foreach my $b (0, 1, undef)
    {
      if(($a || 0) != ($b || 0))
      {
        $i++;

        eval
        {
          $loader->make_classes(warn_on_missing_pk => $a,
                                warn_on_missing_primary_key => $b);
        };

        ok($@, "warn_on_missing_pk conflict $i - $db_type");
      }      
    }
  }

  CATCH_WARNINGS:
  {
    my $warnings;
    local $SIG{'__WARN__'} = sub { $warnings .= "@_\n" };
    @classes = $loader->make_classes(include_tables => $Include_Tables . 
                                     ($db_type eq 'mysql' ? '|read' : ''),
                                     %extra_loader_args);

    #foreach my $class (@classes)
    #{
    #  next unless($class->isa('Rose::DB::Object'));
    #  print $class->meta->perl_class_definition, "\n";
    #}

    if($db_type eq 'sqlite')
    {
      ok($warnings =~ /\QWarning: table 'no_pk_test' has no primary key defined.  Skipping./,
         "warn_on_missing_primary_key - $db_type");
    }
    else
    {
      is($warnings, undef, "warn_on_missing_primary_key - $db_type");
    }
  }

  ok(scalar keys %JCS::Called_Custom_CM >= 3, "custom convention manager - $db_type");
  ok($pre_init_hook > 0, "pre_init_hook - $db_type");

  if($db_type eq 'informix')
  {
    foreach my $class (@classes)
    {
      next  unless($class->isa('Rose::DB::Object'));
      $class->meta->allow_inline_column_values(1);

      if($class->meta->column('release_day'))
      {
        is($class->meta->column('release_day')->type, 'datetime year to month', 
           "datetime year to month - $db_type");
      }
    }
  }
  else
  {
    ok(1, "skip datetime year to month - $db_type");
  }

  if(defined Rose::DB->new->schema)
  {
    ok(!scalar(grep { /NoPk2/i } @classes), "pk classes only - $db_type");
  }
  else
  {
    if($db_type eq 'mysql')
    {
      ok(1, "pk classes - $db_type");
    }
    else
    {
      ok(!scalar(grep { /NoPk\b/i } @classes), "pk classes only - $db_type");
    }
  }

  my $product_class     = $class_prefix . '::Product';
  my $price_class       = $class_prefix . '::Price';
  my $map_manager_class = $class_prefix . '::ProductsColor::Manager';

  ##
  ## Run tests
  ##

  if($db_type =~ /^(?:mysql|pg|sqlite)$/)
  {
    my $serial =
      ($db_type ne 'mysql' || $db->dbh->{'Driver'}{'Version'} >= 4.002) ? 
      'serial' : 'integer';

    is($product_class->meta->column('id')->type, $serial, "serial column - $db_type");
  }
  else
  {
    SKIP: { skip("serial coercion test for $db_type", 1) }
  }

  if($db_type eq 'pg')
  {
    my $uk = $product_class->meta->unique_key_by_name('products_uk_test');
    ok($uk && $uk->has_predicate, "include unique index with predicate - $db_type");
  }
  elsif($db_type eq 'pg_with_schema')
  {
    my $uk = $product_class->meta->unique_key_by_name('products_uk_test');
    ok(!$uk, "skip unique index with predicate - $db_type");
  }
  else
  {
    SKIP: { skip("unique index with predicate for $db_type", 1) }
  }

  if($db_type eq 'pg')
  {
    is($product_class->meta->column('release_date')->type, 'timestamp',
      "timestamp - $db_type");

    is($product_class->meta->column('release_date_tz')->type, 'timestamp with time zone',
      "timestamp with time zone - $db_type");
  }
  else
  {
    SKIP: { skip("timestamp with time zone tests for $db_type", 2) }
  }

  if($db_type eq 'mysql' && $db->dbh->{'Driver'}{'Version'} >= 4.002)
  {
    is($price_class->meta->column('id')->type, 'bigserial', "bigserial column - $db_type");
  }
  else
  {
    SKIP: { skip("bigserial test for $db_type", 1) }
  }

  if($db_type eq 'Pg' || $db_type eq 'mysql')
  {
    is($price_class->meta->column('price')->precision, 10, "decimal precision - $db_type");
    is($price_class->meta->column('price')->scale, 2, "decimal scale - $db_type");
  }
  else
  {
    SKIP: { skip("decimal precision and scale - $db_type yet", 2) }
  }

  if($db_type eq 'informix' || $db_type eq 'oracle')
  {
    SKIP: { skip("count distinct multi-pk doesn't work in \u$db_type yet", 1) }
  }
  else
  {
    my $count = $map_manager_class->get_objects_count(require_objects => [ 'color' ]);
    is($count, 0, "count distinct multi-pk - $db_type");
  }

  my $p = $product_class->new(name => "Sled $i");

  if($p->can('release_day'))
  {
    $p->release_day('2001-02');
    die "datetime year to month not truncated"  unless($p->release_day->day == 1);
    $p->release_day('2001-02-05');
    die "datetime year to month not truncated"  unless($p->release_day->day == 1);
  }

  # Check reserved methods
  foreach my $word (@{$Reserved_Words{$db_type} ||= []})
  {
    ok($p->$word(int(rand(10)) + 1), "reserved word: $word - $db_type");
  }

  is($p->db->class, 'Rose::DB', "db 1 - $db_type");

  if($db_type =~ /^pg/)
  {
    ok($p->can('tee_time') && $p->can('tee_time5'), "time methods - $db_type");
    is($p->meta->column('tee_time5')->scale, 5, "time precision check 1 - $db_type");
    is($p->meta->column('tee_time')->scale || 0, 0, "time precision check 2 - $db_type");
    my $t = $p->tee_time5->as_string;
    $t =~ s/0+$//;
    is($p->tee_time5->as_string, '12:34:56.12345', "time default 1 - $db_type");
    $t = $p->meta->column('tee_time5')->default;
    $t =~ s/0+$//;
    is($t, '12:34:56.12345', "time default 2 - $db_type");
    is($price_class->meta->column('mprice')->length, undef, "money 1 - $db_type");
  }
  elsif($db_type eq 'informix')
  {
    ok(!$p->can('tee_time') && !$p->can('tee_time5'), "time methods - $db_type");
    ok(!$p->meta->column('tee_time5'), "time precision check 1 - $db_type");
    ok(!$p->meta->column('tee_time'), "time precision check 2 - $db_type");
    is($p->meta->column('bint1')->type, 'bigint', "bigint 1 - $db_type");
    ok($p->bint1 =~ /^\+?9223372036854775800$/, "bigint 2 - $db_type");
    SKIP: { skip("money tests - $db_type", 1) }
  }
  else
  {
    ok(!$p->can('tee_time') && !$p->can('tee_time5'), "time methods - $db_type");
    ok(!$p->meta->column('tee_time5'), "time precision check 1 - $db_type");
    ok(!$p->meta->column('tee_time'), "time precision check 2 - $db_type");
    ok(1, "time default 1 - $db_type");
    ok(1, "time default 2 - $db_type");
    SKIP: { skip("money tests - $db_type", 1) }
  }

  OBJECT_CLASS:
  {
    no strict 'refs';
    ok(${"${product_class}::ISA"}[0] =~ /^${class_prefix}::DB::Object::AutoBase\d+$/, "base class 1 - $db_type");
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

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  my $prods = $mgr_class->get_products(query => [ id => $p->id ]);

  is(ref $prods, 'ARRAY', "get_products 1 - $db_type");
  is(@$prods, 1, "get_products 2 - $db_type");
  is($prods->[0]->id, $p->id, "get_products 3 - $db_type");

  #$DB::single = 1;
  #local $Rose::DB::Object::Debug = 1;

  # Reserved tablee name tests
  if($db_type eq 'mysql')
  {
    my $o = Mysql::Read->new(read => 'Foo')->save;
    $o = Mysql::Read->new(id => $o->id)->load;
    is($o->read, 'Foo', "reserved table name 1 - $db_type");
    my $os = Mysql::Read::Manager->get_read;
    ok(@$os == 1 && $os->[0]->read eq 'Foo', "reserved table name 2 - $db_type");

    ok(Mysql::NoPkTest->isa('Rose::DB::Object'), "require_primary_key 1 - $db_type")
  }
  else
  {
    SKIP:
    {
      skip("reserved table name and no pk tests", 3);
    }
  }
}


BEGIN
{
  our %Have;

  our %Reserved_Words =
  (
    'pg' => [ qw(role cast user) ],
    'pg_with_schema' => [ qw(role cast user) ],
    'mysql' => [ qw(read for case) ],
  );

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

      $dbh->do('DROP TABLE no_pk_test CASCADE');
      $dbh->do('DROP TABLE no_pk_test2 CASCADE');
      $dbh->do('DROP TABLE products_colors CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');

      $dbh->do('DROP TABLE Rose_db_object_private.no_pk_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.no_pk_test2 CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.products_colors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.colors CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.prices CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.products CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.vendors CASCADE');

      $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE no_pk_test
(
  id    SERIAL NOT NULL,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE no_pk_test2
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  @{[ join(', ', map { qq("$_" INT) } @{$Reserved_Words{'pg'}}) . ',' ]}

  vendor_id  INT REFERENCES vendors (id),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  tee_time        TIME,
  tee_time5       TIME(5) DEFAULT '12:34:56.12345',

  date_created    TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date    TIMESTAMP,
  release_date_tz TIMESTAMP WITH TIME ZONE,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE UNIQUE INDEX products_uk_test ON products (date_created) WHERE status = 'inactive';
EOF

    $dbh->do(<<"EOF");
CREATE UNIQUE INDEX products_uk1 ON products (LOWER(name))
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  mprice      MONEY,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products_colors
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.no_pk_test
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.no_pk_test2
(
  id    SERIAL NOT NULL,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  @{[ join(', ', map { qq("$_" INT) } @{$Reserved_Words{'pg'}}) . ',' ]}

  vendor_id  INT REFERENCES vendors (id),

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  tee_time        TIME,
  tee_time5       TIME(5) DEFAULT '12:34:56.12345',

  date_created    TIMESTAMP NOT NULL DEFAULT NOW(),
  release_date    TIMESTAMP,
  release_date_tz TIMESTAMP WITH TIME ZONE,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE UNIQUE INDEX products_uk_test ON Rose_db_object_private.products (date_created) WHERE status = 'inactive';
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  mprice      MONEY,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.products_colors
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

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

      $dbh->do('DROP TABLE no_pk_test CASCADE');
      $dbh->do('DROP TABLE products_colors CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');
      $dbh->do('DROP TABLE `read` CASCADE');
    }

    # Foreign key stuff requires InnoDB support
    $dbh->do(<<"EOF");
CREATE TABLE vendors
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
    $sth->execute('vendors');
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
CREATE TABLE no_pk_test
(
  id    INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  @{[ join(', ', map { "`$_` INT" } @{$Reserved_Words{'mysql'}}) . ',' ]}

  vendor_id  INT,

  status  VARCHAR(128) NOT NULL DEFAULT 'inactive' 
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  TIMESTAMP,
  release_date  TIMESTAMP,

  UNIQUE(name),
  INDEX(vendor_id),

  FOREIGN KEY (vendor_id) REFERENCES vendors (id) ON DELETE NO ACTION ON UPDATE SET NULL
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id  INT NOT NULL,
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  UNIQUE(product_id, region),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES products (id) ON UPDATE NO ACTION
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products_colors
(
  product_id  INT NOT NULL,
  color_id    INT NOT NULL,

  PRIMARY KEY(product_id, color_id),

  INDEX(color_id),
  INDEX(product_id),

  FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE NO ACTION,
  FOREIGN KEY (color_id) REFERENCES colors (id) ON UPDATE NO ACTION
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

      $dbh->do('DROP TABLE no_pk_test CASCADE');
      $dbh->do('DROP TABLE products_colors CASCADE');
      $dbh->do('DROP TABLE colors CASCADE');
      $dbh->do('DROP TABLE prices CASCADE');
      $dbh->do('DROP TABLE products CASCADE');
      $dbh->do('DROP TABLE vendors CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE no_pk_test
(
  id    INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES vendors (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  rint1         INT,
  bint1         INT8 DEFAULT 9223372036854775800,

  date_created  DATETIME YEAR TO SECOND,
  release_date  DATETIME YEAR TO SECOND,
  release_day   DATETIME YEAR TO MONTH,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products_colors
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

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

      $dbh->do('DROP TABLE no_pk_test');
      $dbh->do('DROP TABLE products_colors');
      $dbh->do('DROP TABLE colors');
      $dbh->do('DROP TABLE prices');
      $dbh->do('DROP TABLE products');
      $dbh->do('DROP TABLE vendors');
    }

    $dbh->do(<<"EOF");
CREATE TABLE 'no_pk_test'
(
  id    INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE "vendors"
(
  "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE("name")
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT REFERENCES vendors (id),

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  date_created  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  release_date  DATETIME,

  UNIQUE('name')
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INT NOT NULL REFERENCES products (id),
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  UNIQUE(product_id, region)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products_colors
(
  product_id  INT NOT NULL REFERENCES products (id),
  color_id    INT NOT NULL REFERENCES colors (id),

  PRIMARY KEY(product_id, color_id)
)
EOF

    $dbh->disconnect;
  }

  #
  # Oracle
  #

  eval
  {
    $dbh = Rose::DB->new('oracle_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'oracle'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE no_pk_test');
      $dbh->do('DROP TABLE products_colors');
      $dbh->do('DROP TABLE colors');
      $dbh->do('DROP TABLE prices');
      $dbh->do('DROP TABLE products');
      $dbh->do('DROP TABLE vendors');
      $dbh->do('DROP SEQUENCE vendors_id_seq');
      $dbh->do('DROP SEQUENCE products_id_seq');
      $dbh->do('DROP SEQUENCE prices_id_seq');
      $dbh->do('DROP SEQUENCE colors_id_seq');
    }

    $dbh->do(<<"EOF");
CREATE TABLE no_pk_test
(
  id    INT NOT NULL,
  name  VARCHAR(255) NOT NULL,

  CONSTRAINT no_pk_test_name UNIQUE (name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE vendors
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  CONSTRAINT vendors_name UNIQUE (name)
)
EOF

    $dbh->do('CREATE SEQUENCE vendors_id_seq');
    $dbh->do(<<"EOF");
CREATE OR REPLACE TRIGGER vendors_insert BEFORE INSERT ON vendors
FOR EACH ROW
BEGIN
    SELECT NVL(:new.id, vendors_id_seq.nextval)
      INTO :new.id FROM dual;
END;
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products
(
  id      INT NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  price   DECIMAL(10,2) DEFAULT 0.00 NOT NULL,

  vendor_id  INT,

  status  VARCHAR(128) DEFAULT 'inactive' NOT NULL
            CHECK(status IN ('inactive', 'active', 'defunct')),

  rint1         INT,
  bint1         NUMBER(20) DEFAULT 9223372036854775800,

  date_created  TIMESTAMP,

  CONSTRAINT products_name UNIQUE (name),
  CONSTRAINT products_vendor_id_fk FOREIGN KEY (vendor_id) REFERENCES vendors (id)
)
EOF

    $dbh->do('CREATE SEQUENCE products_id_seq');
    $dbh->do(<<"EOF");
CREATE OR REPLACE TRIGGER products_insert BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    SELECT NVL(:new.id, products_id_seq.nextval)
      INTO :new.id FROM dual;
END;
EOF

    $dbh->do(<<"EOF");
CREATE TABLE prices
(
  id          INT NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL,
  region      CHAR(2) DEFAULT 'US' NOT NULL,
  price       NUMBER(10,2) DEFAULT 0.00 NOT NULL,

  CONSTRAINT prices_uk UNIQUE (product_id, region),
  CONSTRAINT prices_product_id_fk FOREIGN KEY (product_id) REFERENCES products (id)
)
EOF

    $dbh->do('CREATE SEQUENCE prices_id_seq');
    $dbh->do(<<"EOF");
CREATE OR REPLACE TRIGGER prices_insert BEFORE INSERT ON prices
FOR EACH ROW
BEGIN
    SELECT NVL(:new.id, prices_id_seq.nextval)
      INTO :new.id FROM dual;
END;
EOF

    $dbh->do(<<"EOF");
CREATE TABLE colors
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  CONSTRAINT colors_name UNIQUE (name)
)
EOF

    $dbh->do('CREATE SEQUENCE colors_id_seq');
    $dbh->do(<<"EOF");
CREATE OR REPLACE TRIGGER colors_insert BEFORE INSERT ON colors
FOR EACH ROW
BEGIN
    SELECT NVL(:new.id, colors_id_seq.nextval)
      INTO :new.id FROM dual;
END;
EOF

    $dbh->do(<<"EOF");
CREATE TABLE products_colors
(
  product_id  INT NOT NULL,
  color_id    INT NOT NULL,

  CONSTRAINT products_colors_pk PRIMARY KEY (product_id, color_id),
  CONSTRAINT products_colors_product_id_fk FOREIGN KEY (product_id) REFERENCES products (id), 
  CONSTRAINT products_colors_color_id_fk FOREIGN KEY (color_id) REFERENCES colors (id)
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

    $dbh->do('DROP TABLE no_pk_test CASCADE');
    $dbh->do('DROP TABLE no_pk_test2 CASCADE');
    $dbh->do('DROP TABLE products_colors CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');

    $dbh->do('DROP TABLE Rose_db_object_private.no_pk_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.no_pk_test2 CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.products_colors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.colors CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.prices CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.products CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.vendors CASCADE');

    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE no_pk_test CASCADE');
    $dbh->do('DROP TABLE products_colors CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');
    $dbh->do('DROP TABLE `read` CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE no_pk_test CASCADE');
    $dbh->do('DROP TABLE products_colors CASCADE');
    $dbh->do('DROP TABLE colors CASCADE');
    $dbh->do('DROP TABLE prices CASCADE');
    $dbh->do('DROP TABLE products CASCADE');
    $dbh->do('DROP TABLE vendors CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE no_pk_test');
    $dbh->do('DROP TABLE products_colors');
    $dbh->do('DROP TABLE colors');
    $dbh->do('DROP TABLE prices');
    $dbh->do('DROP TABLE products');
    $dbh->do('DROP TABLE vendors');

    $dbh->disconnect;
  }

  if($Have{'oracle'})
  {
    # Informix
    my $dbh = Rose::DB->new('oracle_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE no_pk_test');
    $dbh->do('DROP TABLE products_colors');
    $dbh->do('DROP TABLE colors');
    $dbh->do('DROP TABLE prices');
    $dbh->do('DROP TABLE products');
    $dbh->do('DROP TABLE vendors');
    $dbh->do('DROP SEQUENCE vendors_id_seq');
    $dbh->do('DROP SEQUENCE products_id_seq');
    $dbh->do('DROP SEQUENCE prices_id_seq');
    $dbh->do('DROP SEQUENCE colors_id_seq');

    $dbh->disconnect;
  }
}
