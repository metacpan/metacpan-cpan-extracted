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

package Net::MyCommerce::API::Resource::Products;

use strict;
use warnings;

use base qw( Net::MyCommerce::API::Resource );

=head1 NAME
 
Net::MyCommerce::API::Resource::Products
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 SCHEMA

http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/15-schemas-product

=head1 METHODS

=head2 new

Subclass Net::MyCommerce::API::Resource

=cut

sub new {
  my ($pkg, %args) = @_;
  return $pkg->SUPER::new( %args, scope=>'products' );
}

=head2 _vendorID ( $product_id )

Extract vendor_id from product_id

=cut

=head2 get_product

Get a single product

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/6-example-get-products-one-product

=cut

sub get_product {
  my ($self, %opts) = @_;
  my $params = { language => $opts{language} || 'en_US' };
  if ($opts{offer_id}) {
    $params->{offer_id} = $opts{offer_id};
  }
  return $self->request(
    path   => [ '/vendors', $opts{vendor_id}, 'products', $opts{product_id} ],
    params => $params,
  );
}

=head2 get_products

Get full product catalog

Filter options:

  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/11-parameters-product

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/5-example-get-products-base
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/31-example-get-products-expand-and-fields
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/30-example-get-products-limit-and-offset
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/29-example-get-products-status
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/32-example-get-products-affiliate
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/39-example-get-products-custom-fields
  http://help.mycommerce.com/index.php/mycommerce-apis/product-resource/40-example-get-products-language

=cut

sub get_products {
  my ($self, %opts) = @_;
  my $params = {
    limit    =>  $opts{limit} || 50,
    status   =>  'approved',
    expand   =>  'product',
    fields   =>  'id,name',
    language =>  $opts{language} || 'en_US',
  };
  return $self->request(
    path   => [ '/vendors', $opts{vendor_id}, 'products' ],
    params => $params,
  );
}

1;
