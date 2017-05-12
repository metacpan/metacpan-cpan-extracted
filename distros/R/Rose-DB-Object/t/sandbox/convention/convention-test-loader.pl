#!/usr/bin/perl

use lib '../../../lib';
use lib 'lib';

use My::DB;
use Rose::DB::Object::Loader;

my $include_tables = 
  '^(?:' . join('|', qw(product_colors prices products colors vendors)) . ')$';

my $loader = Rose::DB::Object::Loader->new;

$loader->make_classes(include_tables => $include_tables,
                      class_prefix   => 'My::Loaded',
                      #with_foreign_keys  => 0,
                      #with_unique_keys   => 0,
                      #with_relationships => [ 'one to many', 'many to many' ],
                      #db_class           => 'My::DB2',
                      #db      => My::DB->new
                      db_class => 'My::DB');

#print 'FK: ', My::Loaded::Product->meta->foreign_keys, "\n";
#print 'UK: ', My::Loaded::Product->meta->unique_keys, "\n";

$p = My::Loaded::Product->new(id => 1)->load;
print $p->vendor->name, "\n";

print join(', ', map { $_->region . ': ' . $_->price } $p->prices), "\n";
print join(', ', map { $_->name } $p->colors), "\n";

# Testing subselect limit
#local $Rose::DB::Object::Manager::Debug = 1;
my $ps = 
  My::Loaded::Product::Manager->get_products(
    with_objects    => [ 'prices' ],
    require_objects => [ 'vendor', 'colors' ],
    multi_many_ok => 1,
    query  => [ 't1.id' => { lt => 999 }, 'prices.price' => 9 ],
    limit  => 1,
    offset => 1);

__END__

DROP TABLE product_colors CASCADE;
DROP TABLE prices CASCADE;
DROP TABLE products CASCADE;
DROP TABLE colors CASCADE;
DROP TABLE vendors CASCADE;

CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
);

CREATE TABLE colors
(
  code  CHAR(3) NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
);

CREATE TABLE products
(
  id        SERIAL NOT NULL PRIMARY KEY,
  name      VARCHAR(255),
  vendor_id INT NOT NULL REFERENCES vendors (id),

  UNIQUE(name)
);

CREATE TABLE prices
(
  price_id    SERIAL NOT NULL PRIMARY KEY,
  product_id  INT NOT NULL REFERENCES products (id),
  region      CHAR(2) NOT NULL DEFAULT 'US',
  price       DECIMAL(10,2) NOT NULL
);

CREATE TABLE product_colors
(
  id           SERIAL NOT NULL PRIMARY KEY,
  product_id   INT NOT NULL REFERENCES products (id),
  color_code   CHAR(3) NOT NULL REFERENCES colors (code)
);

INSERT INTO vendors (id, name) VALUES (1, 'V1');
INSERT INTO vendors (id, name) VALUES (2, 'V2');

INSERT INTO products (id, name, vendor_id) VALUES (1, 'A', 1);
INSERT INTO products (id, name, vendor_id) VALUES (2, 'B', 2);
INSERT INTO products (id, name, vendor_id) VALUES (3, 'C', 1);

INSERT INTO prices (product_id, region, price) VALUES (1, 'US', 1.23);
INSERT INTO prices (product_id, region, price) VALUES (1, 'DE', 4.56);
INSERT INTO prices (product_id, region, price) VALUES (2, 'US', 5.55);
INSERT INTO prices (product_id, region, price) VALUES (3, 'US', 5.78);
INSERT INTO prices (product_id, region, price) VALUES (3, 'US', 9.99);

INSERT INTO colors (code, name) VALUES ('CC1', 'red');
INSERT INTO colors (code, name) VALUES ('CC2', 'green');
INSERT INTO colors (code, name) VALUES ('CC3', 'blue');
INSERT INTO colors (code, name) VALUES ('CC4', 'pink');

INSERT INTO product_colors (product_id, color_code) VALUES (1, 'CC1');
INSERT INTO product_colors (product_id, color_code) VALUES (1, 'CC2');

INSERT INTO product_colors (product_id, color_code) VALUES (2, 'CC4');

INSERT INTO product_colors (product_id, color_code) VALUES (3, 'CC2');
INSERT INTO product_colors (product_id, color_code) VALUES (3, 'CC3');
