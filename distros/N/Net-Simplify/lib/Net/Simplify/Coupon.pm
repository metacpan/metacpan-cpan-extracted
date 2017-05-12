package Net::Simplify::Coupon;

=head1 NAME

Net::Simplify::Coupon - A Simplify Commerce Coupon object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new Coupon.
  my $coupon = Net::Simplify::Coupon->create{ {...});

  # Retrieve a Coupon given its ID.
  my $coupon = Net::Simplify::Coupon->find('a7e41');

  # Update existing Coupon.
  my $coupon = Net::Simplify::Coupon->find('a7e41');
  $coupon->{PROPERTY} = "NEW VALUE";
  $coupon->update();

  # Delete
  my $coupon = Net::Simplify::Coupon->find('a7e41');
  $coupon->delete();

  # Retrieve a list of objects
  my $coupons = Net::Simplify::Coupon->list({max => 10});
  foreach my $v ($coupons->list) {
      # ...
  }

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::Coupon> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4

=item amountOff

Amount off of the price of the product in the smallest units of the currency of the merchant. While this field is optional, you must provide either amountOff or percentOff for a coupon. Example: 100 = $1.00USD [min value: 1] 

=item couponCode

Code that identifies the coupon to be used. [min length: 2] (B<required>) 

=item description

A brief section that describes the coupon. 

=item durationInMonths

DEPRECATED - Duration in months that the coupon will be applied after it has first been selected. [min value: 1, max value: 9999] 

=item endDate

Last date of the coupon in UTC millis that the coupon can be applied to a subscription. This ends at 23:59:59 of the merchant timezone. 

=item maxRedemptions

Maximum number of redemptions allowed for the coupon. A redemption is defined as when the coupon is applied to the subscription for the first time. [min value: 1] 

=item numTimesApplied

The number of times a coupon will be applied on a customer's subscription. [min value: 1, max value: 9999] 

=item percentOff

Percentage off of the price of the product. While this field is optional, you must provide either amountOff or percentOff for a coupon. The percent off is a whole number. [min value: 1, max value: 100] 

=item startDate

First date of the coupon in UTC millis that the coupon can be applied to a subscription. This starts at midnight of the merchant timezone. (B<required>) 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 delete()

Deletes the C<Net::Simplify::Coupon> object.  Authentication is done using the same credentials used when the AccessToken was created.



=head3 list(%criteria, $auth)

Retrieve a list of C<Net::Simplify::Coupon> objects.  The parameters are:

=over 4

=item C<%criteria>

Hash map representing the criteria to limit the results of the list operation.  Valid keys are:

=over 4

=item C<filter>

Filters to apply to the list.



=item C<max>

Allows up to a max of 50 list items to return. [min value: 0, max value: 50, default: 20]



=item C<offset>

Used in paging of the list.  This is the start offset of the page. [min value: 0, default: 0]



=item C<sorting>

Allows for ascending or descending sorting of the list.
The value maps properties to the sort direction (either C<asc> for ascending or C<desc> for descending).  Sortable properties are:

=over 4

=item C<dateCreated>

=item C<maxRedemptions>

=item C<timesRedeemed>

=item C<id>

=item C<startDate>

=item C<endDate>

=item C<percentOff>

=item C<couponCode>

=item C<durationInMonths>

=item C<numTimesApplied>

=item C<amountOff>


=back




=back

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::Coupon> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 update()

Update C<Net::Simplify::Coupon> object.
The properties that can be updated are:

=over 4


=item C<endDate>

The ending date in UTC millis for the coupon. This must be after the starting date of the coupon. 


=item C<maxRedemptions>

Maximum number of redemptions allowed for the coupon. A redemption is defined as when the coupon is applied to the subscription for the first time. [min value: 1] 

Authentication is done using the same credentials used when the AccessToken was created.

=back




=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::Domain>,
L<Net::Simplify::DomainList>,
L<Net::Simplify::Authentication>,
L<Net::Simplify::ApiException>,
L<http://www.simplify.com>

=head1 VERSION

1.5.0

=head1 LICENSE

Copyright (c) 2013 - 2016 MasterCard International Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of 
conditions and the following disclaimer in the documentation and/or other materials 
provided with the distribution.
Neither the name of the MasterCard International Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from this software 
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

=head1 SEE ALSO

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Simplify::Domain;
use Net::Simplify::DomainList;

our @ISA = qw(Net::Simplify::Domain);

sub create {

    my ($class, $params, $auth) = @_;
    
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("coupon", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub delete {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});

    my $id = $self->{id};
    $self->merge(Net::Simplify::SimplifyApi->send_api_request("coupon", 'delete', {id => $id}, $auth));
}

sub list {
    my ($class, $criteria, $auth) = @_;
   
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("coupon", 'list', $criteria, $auth);

    Net::Simplify::DomainList->new($result, $class, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("coupon", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}

sub update {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});
    my $params = { %$self };
    delete $params->{_authentication};

    $self->merge(Net::Simplify::SimplifyApi->send_api_request("coupon", 'update', $params, $auth));
}


1;
