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

package Net::MyCommerce::API::Resource::Orders;

use strict;
use warnings;

use base qw( Net::MyCommerce::API::Resource );

=head1 NAME
 
Net::MyCommerce::API::Resource::Orders
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 SCHEMA

http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/16-schemas-order

=head1 METHOD

=head2 new 

Subclass Net::MyCommerce::API::Resource

=cut

sub new {
  my ($pkg, %args) = @_;
  return $pkg->SUPER::new( %args, scope=>'orders' );
}

=head2 get_order

Get an order

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/22-example-get-order

=cut

sub get_order {
  my ($self, %opts) = @_;
  $opts{path} = [ '/orders', $opts{order_id} ];
  return $self->request(%opts);
}

=head2 get_orders

Get orders 

Filter options:

  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/12-parameters-order

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/27-example-get-orders-base
  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/24-example-get-orders-expand-and-fields
  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/25-example-get-orders-limit-and-offset
  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/23-example-get-orders-date-range
  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/26-example-get-orders-status

=cut

sub get_orders {
  my ($self, %opts) = @_;
  $opts{path} = '/orders';
  return $self->request(%opts);
}

=head2 get_line_item

Get an order line item

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/22-example-get-order

=cut

sub get_line_item {
  my ($self, %opts) = @_;
  $opts{path} = [ '/orders', $opts{order_id}, 'lineitems', $opts{lineitem_id} ];
  return $self->request(%opts);
}

=head2 get_line_items

Get all line items in an order

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/order-resource/22-example-get-order

=cut

sub get_line_items {
  my ($self, %opts) = @_;
  $opts{path} = [ '/orders', $opts{order_id}, 'lineitems' ];
  return $self->request(%opts);
}

1;
