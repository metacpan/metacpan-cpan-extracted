#!/usr/bin/env perl
 
#  Copyright 2013 Digital River, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;

use lib qw( ../lib );
 
use Net::MyCommerce::API;
 
my ($vendor_id, $vendor_secret, $product_id_1, $product_id_2) = @ARGV;
unless ($vendor_id && $vendor_secret && $product_id_1 && $product_id_2) {
  die "Usage: ./carts.pl VENDOR_ID API_SECRET PRODUCT_ID_1 PRODUCT_ID_2\n";
}
 
my $api = Net::MyCommerce::API->new()->carts( credentials => { id=>$vendor_id, secret=>$vendor_secret } );
 
print "CREATE CART ($product_id_1)\n";
my ($err, $res) = $api->create_cart( item=> { product_id=>$product_id_1, quantity=>1 } );
die $err if $err;
my $cart_id = $res->{content}{id};
print "CART ID ($cart_id)\n";

print "ADD ITEM ($product_id_2)\n";
($err, $res) = $api->add_item( cart_id=>$cart_id, item=> { product_id=>$product_id_2, quantity=>2 } );
die $err if $err;
my %item_id = ();
foreach my $item (@{$res->{content}{items}}) {
  print "ITEM ID ($item->{product_id}, $item->{id}, $item->{quantity})\n";
  $item_id{$item->{product_id}} = $item->{id};
}

print "UPDATE ITEMS ($item_id{$product_id_2})\n";
($err, $res) = $api->update_items( cart_id=>$cart_id, items=> [{ id=>$item_id{$product_id_2}, quantity=>3 }] );
die $err if $err;
foreach my $item (@{$res->{content}{items}}) {
  print "ITEM ID ($item->{product_id}, $item->{id}, $item->{quantity})\n";
}

print "REMOVE ITEM ($item_id{$product_id_2}})\n";
($err, $res) = $api->remove_item( cart_id=>$cart_id, item_id=>$item_id{$product_id_2} );
die $err if $err;

print "GET CART ($cart_id)\n";
($err, $res) = $api->get_cart( cart_id=>$cart_id );
die $err if $err;
foreach my $item (@{$res->{content}{items}}) {
  print "ITEM ID ($item->{product_id}, $item->{id}, $item->{quantity})\n";
}

print "GET ITEM ($item_id{$product_id_1}})\n";
($err, $res) = $api->get_item( cart_id=>$cart_id, item_id=>$item_id{$product_id_1} );
die $err if $err;
print "ITEM ID ($res->{content}{product_id}, $res->{content}{id}, $res->{content}{quantity})\n";

