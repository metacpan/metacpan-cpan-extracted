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

package Net::MyCommerce::API::Resource::Vendors;

use strict;
use warnings;

use base qw( Net::MyCommerce::API::Resource );

=head1 NAME
 
Net::MyCommerce::API::Resource::Vendors
 
=head1 VERSION
 
version 1.0.1
 
=cut
 
our $VERSION = '1.0.1';
 
=head1 SCHEMA

http://help.mycommerce.com/index.php/mycommerce-apis/vendor-resource/17-schemas-vendor

=head1 METHODS

=head2 new ($args)

Subclass Net::MyCommerce::API::Resource

=cut

sub new {
  my ($pkg, %args) = @_;
  return $pkg->SUPER::new( %args, scope=>'vendor' );
}

=head2 get_vendor

Get vendor contact information

Example:

  http://help.mycommerce.com/index.php/mycommerce-apis/vendor-resource/33-example-get-vendor

=cut

sub get_vendor {
  my ($self, %opts) = @_;
  return $self->request( path => [ '/vendors', $opts{vendor_id} ] );
}

1;
