#!/usr/bin/perl

use lib '../../../../Rose-DB/lib';
use lib '../../../lib';
use lib 'lib';

use My::Product;

# use My::Price;
# use My::Color;
# use My::Vendor;
# $p = My::Product->new(id => 1, name => 'A');
# $p->prices(My::Price->new(product_id => 1, region => 'IS', price => 1.23),
#            My::Price->new(product_id => 1, region => 'DE', price => 4.56));
# 
# $p->colors(My::Color->new(code => 'CC1', name => 'red'),
#            My::Color->new(code => 'CC2', name => 'green'));
# 
# $p->vendor(My::Vendor->new(id => 1, name => 'V1'));
# $p->save;

$p = My::Product->new(id => 1)->load;
print $p->vendor->name, "\n";

print join(', ', map { $_->region . ': ' . $_->price } $p->prices), "\n";
print join(', ', map { $_->name } $p->colors), "\n";

$c = My::Color->new(name => 'red')->load;

print $c->name, ': ', $c->code, "\n";

#My::Product->meta->auto_load_related_classes(0);
#print My::Product->meta->perl_class_definition(braces => 'bsd', indent => 2);

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
  vendor_id INT NOT NULL REFERENCES vendors (id)
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
