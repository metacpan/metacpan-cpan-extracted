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

package Net::MyCommerce::API::Resource::PAR;

use strict;
use warnings;

use base qw( Net::MyCommerce::API::Resource );

=head1 NAME
 
Net::MyCommerce::API::Resource::PAR
 
=head1 VERSION
 
version 1.0.0
 
=cut
 
our $VERSION = '1.0.0';
 
=head1 SCHEMA

http://help.mycommerce.com/index.php/mycommerce-apis/TBD

=head1 METHODS

=head2 new ($args)

Subclass Net::MyCommerce::API::Resource

=cut 

sub new {
  my ($pkg, %args) = @_;
  return $pkg->SUPER::new( %args, scope=>'payments' );
}

=head2 request (%opts)

Subclass Net::MyCommerce::API::Resource::request

=cut 

sub request {
  my ($self, %opts) = @_;
  $opts{params} ||= {};
  return $self->SUPER::request(%opts);
}

=head2 create_par (%opts)

Create a new Payment Account Resource

Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/TBD

=cut

sub create_par {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'POST',
    path   => '/payment-accounts',
    params => $opts{params},
    data   => { 
      billing_address => $opts{billing_address},
      cc_number       => $opts{cc_number},
      exp_month       => $opts{exp_month},
      exp_year        => $opts{exp_year},
      payment_type    => $opts{payment_type},
      currency_id     => $opts{currency_id},
      cvv_code        => $opts{cvv_code},
    },
  );  
}

=head2 update_par (%opts)

Update Payment Account Resource

=cut

sub update_par {
  my ($self, %opts) = @_;
  return $self->request(
    method => 'POST',
    path   => [ '/payment-accounts', $opts{cart_id} ],
    params => $opts{params},
    data   => { 
      ( $opts{billing_address} ? (billing_address => $opts{billing_address}) : () ),
      ( $opts{cc_number}       ? (cc_number       => $opts{cc_number})       : () ),
      ( $opts{exp_month}       ? (exp_month       => $opts{exp_month})       : () ),
      ( $opts{exp_year}        ? (exp_year        => $opts{exp_year})        : () ),
      ( $opts{payment_type}    ? (payment_type    => $opts{payment_type})    : () ),
      ( $opts{currency_id}     ? (currency_id     => $opts{currency_id})     : () ),
      ( $opts{cvv_code}        ? (cvv_code        => $opts{cvv_code})        : () ),
    },
  );  
}

=head2 get_par (%opts)

Retrieve an existing Payment Account Resource
 
Examples:

  http://help.mycommerce.com/index.php/mycommerce-apis/TBD

=cut 

sub get_par {
  my ($self, %opts) = @_;
  my ($error, $result) = $self->request(
    method => 'GET',
    path   => [ '/payment-accounts', $opts{par_id} ],
    params => $opts{params},
  );
  return ($error, $result);
}

1;
