#!/usr/bin/perl

use strict;

use lib '../../../lib';
use lib 'lib';

use My::Product;

package My::Product;

sub average_price
{
  my($self) = shift;

  my %args;

  if(my $ref = ref $_[0])
  {
    if($ref eq 'HASH')
    {
      %args = (query => [ %{shift(@_)} ], @_);
    }
    elsif(ref $_[0] eq 'ARRAY')
    {
      %args = (query => shift, @_);
    }
  }
  else { %args = @_ }

  my $meta         = $self->meta;
  my $relationship = $self->meta->relationship('prices');
  my $ft_columns   = $relationship->key_columns;
  my $query_args   = $relationship->query_args || [];
  my $mgr_args     = $relationship->manager_args || {};

  my $average;

  # Get query key
  my %key;

  while(my($local_column, $foreign_column) = each(%$ft_columns))
  {
    my $local_method = $meta->column_accessor_method_name($local_column);

    $key{$foreign_column} = $self->$local_method();

    # Comment this out to allow null keys
    unless(defined $key{$foreign_column})
    {
      keys(%$ft_columns); # reset iterator
      $self->error("Could not get average via average_price() - the " .
                   "$local_method attribute is undefined");
      return;
    }
  }

  # Merge query args
  my @query = (%key, @$query_args, @{delete $args{'query'} || []});      

  # Merge the rest of the arguments
  foreach my $param (keys %args)
  {
    if(exists $mgr_args->{$param})
    {
      my $ref = ref $args{$param};

      if($ref eq 'ARRAY')
      {
        unshift(@{$args{$param}}, ref $mgr_args->{$param} ? 
                @{$mgr_args->{$param}} :  $mgr_args->{$param});
      }
      elsif($ref eq 'HASH')
      {
        while(my($k, $v) = each(%{$mgr_args->{$param}}))
        {
          $args{$param}{$k} = $v  unless(exists $args{$param}{$k});
        }
      }
    }
  }

  while(my($k, $v) = each(%$mgr_args))
  {
    $args{$k} = $v  unless(exists $args{$k});
  }

  $args{'object_class'} = $relationship->class;

  my $debug = $Rose::DB::Object::Manager::Debug || $args{'debug'};

  # Make query for average
  eval
  {
    my($sql, $bind) = 
      Rose::DB::Object::Manager->get_objects_sql(
        select => [ \q(AVG(price)) ],
        query => \@query, db => $self->db, %args);

    $debug && warn "$sql (", join(', ', @$bind), ")\n";

    my $sth = $self->db->dbh->prepare($sql);
    $sth->execute(@$bind);

    $average = $sth->fetchrow_array;
  };

  if($@)
  {
    $self->error("Could not average $args{'object_class'} objects - " . 
                 Rose::DB::Object::Manager->error);
    $meta->handle_error($self);
    return wantarray ? () : $average;
  }

  return $average;
}


package main;

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

my $p = My::Product->new(id => 1)->load;

print "AVG(price) = ", $p->average_price, "\n";
print $p->vendor->name, "\n";

print join(', ', map { $_->region . ': ' . $_->price } $p->prices), "\n";
print join(', ', map { $_->name } $p->colors), "\n";

# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     name => { like => 'Kite%' },
#     id   => { gt => 15 },
#   ],
#   require_objects => [ 'vendor' ],
#   with_objects    => [ 'colors', 'prices' ],
#   multi_many_ok   => 1,
#   sort_by => 'name');
# 
# 
# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     name => { like => 'Kite%' },
#     id   => { gt => 15 },
#   ],
#   require_objects => [ 'vendor' ],
#   with_objects    => [ 'colors' ],
#   sort_by => 'name');
# 
# 
# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     name => { like => 'Kite%' },
#     id   => { gt => 15 },
#   ],
#   with_objects => [ 'colors' ],
#   sort_by => 'name');
# 
# 
# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     name => { like => 'Kite%' },
#     id   => { gt => 15 },
#   ],
#   require_objects => [ 'vendor' ],
#   with_objects    => [ 'prices' ],
#   sort_by => 'name');
# 
# 
# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     name => { like => 'Kite%' },
#     id   => { gt => 15 },
#   ],
#   with_objects => [ 'prices' ],
#   sort_by => 'name');
# 
# 
# Rose::DB::Object::Manager->get_objects(
#   object_class => 'My::Product',
#   debug => 1,
#   query =>
#   [
#     'vendor.region.name' => 'UK',
#     'name' => { like => 'Kite%' },
#     'id'   => { gt => 15 },
#   ],
#   require_objects => [ 'vendor.region' ],
#   with_objects    => [ 'colors', 'prices' ],
#   multi_many_ok   => 1,
#   sort_by => 'name');

__END__

DROP TABLE product_colors CASCADE;
DROP TABLE prices CASCADE;
DROP TABLE products CASCADE;
DROP TABLE colors CASCADE;
DROP TABLE vendors CASCADE;
DROP TABLE regions CASCADE;

CREATE TABLE regions
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255)
);

CREATE TABLE vendors
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(255),
  region_id INT REFERENCES regions (id)
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
