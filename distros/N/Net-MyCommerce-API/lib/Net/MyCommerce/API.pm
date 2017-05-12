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

package Net::MyCommerce::API;

use strict;
use warnings;
use Net::MyCommerce::API::Resource;
use Net::MyCommerce::API::Resource::Carts;
use Net::MyCommerce::API::Resource::Orders;
use Net::MyCommerce::API::Resource::PAR;
use Net::MyCommerce::API::Resource::Products;
use Net::MyCommerce::API::Resource::Vendors;

=pod

=head1 NAME

Net::MyCommerce::API

=head1 DESCRIPTION 

REST API to Digital River's MyCommerce Platform

=head1 DOCUMENTATION 

http://help.mycommerce.com/mycommerce-apis

=head1 VERSION

version 1.0.4

=cut

our $VERSION = '1.0.4';

=head1 METHODS 

=head2 new 

Entry point to various Net MyCommerce API resources

  my $api = Net::MyCommerce::API->new();
  my $cart_resource = $api->carts( credentials => { id=> $id, secret => $secret } );
  my ($error, $result) = $cart_resource->create_cart( $options );

=cut

sub new {
  my $pkg = shift;
  return bless {}, $pkg;
}

=head2 carts (%args)

Return a new carts-scope API resource

=cut

sub carts {
  my ($self, %args) = @_;
  return Net::MyCommerce::API::Resource::Carts->new(%args);
}

=head2 orders (%args)

Return a new orders-scope API resource

=cut

sub orders {
  my ($self, %args) = @_;
  return Net::MyCommerce::API::Resource::Orders->new(%args);
}

=head2 par (%args)

Return a new payments-scope API resource

=cut

sub par {
  my ($self, %args) = @_;
  return Net::MyCommerce::API::Resource::PAR->new(%args);
}

=head2 products (%args)

Return a new products-scope API resource

=cut

sub products {
  my ($self, %args) = @_;
  return Net::MyCommerce::API::Resource::Products->new(%args);
}

=head2 vendors ( %args)

Return a new vendors-scope API resource

=cut

sub vendors {
  my ($self, %args) = @_;
  return Net::MyCommerce::API::Resource::Vendors->new(%args);
}

1;
