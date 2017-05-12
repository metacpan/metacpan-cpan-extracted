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

package Net::MyCommerce::API::Resource::Carts;

use strict;
use warnings;

use base qw( Net::MyCommerce::API::Resource );

=head1 NAME
 
Net::MyCommerce::API::Resource::Carts
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 SCHEMA

http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/14-schemas-cart

=head1 METHODS

=head2 new ($args)

Subclass Net::MyCommerce::API::Resource

=cut 

sub new {
  my ($pkg, %args) = @_;
  return $pkg->SUPER::new( %args, scope=>'carts' );
}

=head2 request (%opts)

Subclass Net::MyCommerce::API::Resource::request

=cut 

sub request {
  my ($self, %opts) = @_;
  $opts{params} ||= {};
  $opts{params}->{language} ||= 'en_US';
  return $self->SUPER::request(%opts);
}

=head2 create_cart

Create a new cart

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/7-example-create-cart-simple-one-product
  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/21-example-create-cart-fill-in-shopper-information
  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/18-example-create-cart-affiliate
  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/35-example-create-shopping-cart-custom-fields
  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/36-example-create-shopping-cart-offers

=cut

sub create_cart {
  my ($self, %opts) = @_;
  $opts{item} ||= {};
  return $self->request(
    method => 'POST',
    path   => '/carts',
    params => $opts{params},
    data   => { 
      items => [ 
        { 
          product_id => $opts{item}->{product_id}, 
          quantity   => $opts{item}->{quantity},
        },
      ]
    },
  );  
}

=head2 add_item

Add a new item to an existing shopping cart

=cut

sub add_item {
  my ($self, %opts) = @_;
  $opts{item} ||= {};
  return $self->request(
    method => 'POST',
    path   => $opts{cart_id} ? [ '/carts', $opts{cart_id} ] : '/carts',
    params => $opts{params},
    data   => { 
      items => [ 
        { 
          product_id    => $opts{item}->{product_id}, 
          quantity      => $opts{item}->{quantity},
          custom_fields => $opts{item}->{custom_fields},
          offer_id      => $opts{item}->{offer_id},
        },
      ]
    },
  );  
}

=head2 update_items

Add/modify one or more items in an existing shopping cart

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/20-example-update-cart-set-quantity

=cut

sub update_items {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'POST',
    path   => [ '/carts', $opts{cart_id} ],
    params => $opts{params},
    data   => { 
      items       => $opts{items},
      coupon_code => $opts{coupon_code},
    },
  );  
}

=head2 update_cart

Update shopping cart: one or more items, billing/shipping address, and/or coupon

=cut

sub update_cart {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'POST',
    path   => [ '/carts', $opts{cart_id} ],
    params => $opts{params},
    data   => { 
      ( $opts{billing_address}  ? (billing_address  => $opts{billing_address})  : () ),
      ( $opts{shipping_address} ? (shipping_address => $opts{shipping_address}) : () ),
      ( $opts{items}            ? (items            => $opts{items})            : () ),
      ( $opts{coupon_code}      ? (coupon_code      => $opts{coupon_code})      : () ),
    },
  );  
}

=head2 remove_item

Remove an item from an existing shopping cart

=cut

sub remove_item {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'DELETE',
    path   => [ '/carts', $opts{cart_id}, 'items', $opts{item_id} ],
  );
}

=head2 get_cart

Retrieve an existing shopping cart
 
Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/19-example-get-cart 
  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/38-example-get-shopping-cart-select-or-hide-fields

=cut 

sub get_cart {
  my ($self, %opts) = @_;
  my ($error, $result) = $self->request(
    method => 'GET',
    path   => [ '/carts', $opts{cart_id} ],
    params => $opts{params},
  );
  return ($error, $result) if $error;
  if (ref($result) eq 'HASH' && 
      ref($result->{content}) eq 'HASH' &&
      ref($result->{content}{items}) eq 'ARRAY') {
    foreach my $item (@{$result->{content}{items}}) {
      my $p = $item->{pricing};
      my $q = $item->{quantity} || 1;
      $p->{non_discount_total}  = sprintf("%.2f", $p->{total} + $p->{discount});
      $p->{discount_unit_price} = sprintf("%.2f", $p->{unit_price} - $p->{discount}/$q); 
    }
    my $discount = $result->{content}{pricing}{discount};
    $result->{content}{pricing}{discount} = sprintf("%.2f",$discount) if $discount;
  }
  return ($error, $result);
}

=head2 get_item

Retrieve a single item from an existing shopping cart

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/cart-resource/19-example-get-cart

=cut 

sub get_item {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'GET',
    path   => [ '/carts', $opts{cart_id}, 'items', $opts{item_id} ],
    params => $opts{params},
  );
}

1;
