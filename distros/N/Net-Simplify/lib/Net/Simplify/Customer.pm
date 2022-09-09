package Net::Simplify::Customer;

=head1 NAME

Net::Simplify::Customer - A Simplify Commerce Customer object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new Customer.
  my $customer = Net::Simplify::Customer->create{ {...});

  # Retrieve a Customer given its ID.
  my $customer = Net::Simplify::Customer->find('a7e41');

  # Update existing Customer.
  my $customer = Net::Simplify::Customer->find('a7e41');
  $customer->{PROPERTY} = "NEW VALUE";
  $customer->update();

  # Delete
  my $customer = Net::Simplify::Customer->find('a7e41');
  $customer->delete();

  # Retrieve a list of objects
  my $customers = Net::Simplify::Customer->list({max => 10});
  foreach my $v ($customers->list) {
      # ...
  }

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::Customer> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4



=item card.addressCity

City of the cardholder. (B<required>) 

=item card.addressCountry

Country code (ISO-3166-1-alpha-2 code) of residence of the cardholder. (B<required>) 

=item card.addressLine1

Address of the cardholder (B<required>) 

=item card.addressLine2

Address of the cardholder if needed. (B<required>) 

=item card.addressState

State of residence of the cardholder. State abbreviations should be used. (B<required>) 

=item card.addressZip

Postal code of the cardholder. The postal code size is between 5 and 9 in length and only contain numbers or letters. (B<required>) 

=item card.cvc

CVC security code of the card. This is the code on the back of the card. Example: 123 (B<required>) 

=item card.expMonth

Expiration month of the card. Format is MM. Example: January = 01 (B<required>) 

=item card.expYear

Expiration year of the card. Format is YY. Example: 2013 = 13 (B<required>) 

=item card.id

ID of card. Unused during customer create. 

=item card.name

Name as appears on the card. (B<required>) 

=item card.number

Card number as it appears on the card. [max length: 19, min length: 13] 

=item email

Email address of the customer (B<required>) 

=item name

Customer name [max length: 50, min length: 2] (B<required>) 

=item reference

Reference field for external applications use. 



=item subscriptions.amount

Amount of payment in the smallest unit of your currency. Example: 100 = $1.00 

=item subscriptions.billingCycle

How the plan is billed to the customer. Values must be AUTO (indefinitely until the customer cancels) or FIXED (a fixed number of billing cycles). [default: AUTO] 

=item subscriptions.billingCycleLimit

The number of fixed billing cycles for a plan. Only used if the billingCycle parameter is set to FIXED. Example: 4 

=item subscriptions.coupon

Coupon associated with the subscription for the customer. 

=item subscriptions.currency

Currency code (ISO-4217). Must match the currency associated with your account. 

=item subscriptions.currentPeriodEnd

End date of subscription's current period 

=item subscriptions.currentPeriodStart

Start date of subscription's current period 

=item subscriptions.customer

The customer ID to create the subscription for. Do not supply this when creating a customer. 

=item subscriptions.frequency

Frequency of payment for the plan. Used in conjunction with frequencyPeriod. Valid values are "DAILY", "WEEKLY", "MONTHLY" and "YEARLY". 

=item subscriptions.frequencyPeriod

Period of frequency of payment for the plan. Example: if the frequency is weekly, and periodFrequency is 2, then the subscription is billed bi-weekly. 

=item subscriptions.name

Name describing subscription [max length: 50] 

=item subscriptions.plan

The plan ID that the subscription should be created from. 

=item subscriptions.quantity

Quantity of the plan for the subscription. [min value: 1] 

=item subscriptions.renewalReminderLeadDays

If set, how many days before the next billing cycle that a renewal reminder is sent to the customer. If null, then no emails are sent. Minimum value is 7 if set. 

=item subscriptions.source

Source of where subscription was created 

=item token

If specified, card associated with card token will be used 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 delete()

Deletes the C<Net::Simplify::Customer> object.  Authentication is done using the same credentials used when the AccessToken was created.



=head3 list(%criteria, $auth)

Retrieve a list of C<Net::Simplify::Customer> objects.  The parameters are:

=over 4

=item C<%criteria>

Hash map representing the criteria to limit the results of the list operation.  Valid keys are:

=over 4

=item C<filter>

<table class="filter_list"><tr><td>filter.id</td><td>Filter by the customer Id</td></tr><tr><td>filter.text</td><td>Can use this to filter by the name, email or reference for the customer</td></tr><tr><td>filter.dateCreatedMin<sup>*</sup></td><td>Filter by the minimum created date you are searching for - Date in UTC millis</td></tr><tr><td>filter.dateCreatedMax<sup>*</sup></td><td>Filter by the maximum created date you are searching for - Date in UTC millis</td></tr></table><br><sup>*</sup>Use dateCreatedMin with dateCreatedMax in the same filter if you want to search between two created dates



=item C<max>

Allows up to a max of 50 list items to return. [min value: 0, max value: 50, default: 20]



=item C<offset>

Used in paging of the list.  This is the start offset of the page. [min value: 0, default: 0]



=item C<sorting>

Allows for ascending or descending sorting of the list.
The value maps properties to the sort direction (either C<asc> for ascending or C<desc> for descending).  Sortable properties are:

=over 4

=item C<dateCreated>

=item C<id>

=item C<name>

=item C<email>

=item C<reference>


=back




=back

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::Customer> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 update()

Update C<Net::Simplify::Customer> object.
The properties that can be updated are:

=over 4


=item C<card.addressCity>

City of the cardholder. (B<required>) 

=item C<card.addressCountry>

Country code (ISO-3166-1-alpha-2 code) of residence of the cardholder. (B<required>) 

=item C<card.addressLine1>

Address of the cardholder. (B<required>) 

=item C<card.addressLine2>

Address of the cardholder if needed. (B<required>) 

=item C<card.addressState>

State of residence of the cardholder. State abbreviations should be used. (B<required>) 

=item C<card.addressZip>

Postal code of the cardholder. The postal code size is between 5 and 9 in length and only contain numbers or letters. (B<required>) 

=item C<card.cvc>

CVC security code of the card. This is the code on the back of the card. Example: 123 (B<required>) 

=item C<card.expMonth>

Expiration month of the card. Format is MM.  Example: January = 01 (B<required>) 

=item C<card.expYear>

Expiration year of the card. Format is YY. Example: 2013 = 13 (B<required>) 

=item C<card.id>

ID of card. If present, card details for the customer will not be updated. If not present, the customer will be updated with the supplied card details. 

=item C<card.name>

Name as appears on the card. (B<required>) 

=item C<card.number>

Card number as it appears on the card. [max length: 19, min length: 13] 

=item C<email>

Email address of the customer (B<required>) 


=item C<name>

Customer name [max length: 50, min length: 2] (B<required>) 

=item C<reference>

Reference field for external applications use. 

=item C<token>

If specified, card associated with card token will be added to the customer 

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

1.6.0

=head1 LICENSE

Copyright (c) 2013 - 2022 MasterCard International Incorporated
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
    my $result = Net::Simplify::SimplifyApi->send_api_request("customer", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub delete {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});

    my $id = $self->{id};
    $self->merge(Net::Simplify::SimplifyApi->send_api_request("customer", 'delete', {id => $id}, $auth));
}

sub list {
    my ($class, $criteria, $auth) = @_;
   
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("customer", 'list', $criteria, $auth);

    Net::Simplify::DomainList->new($result, $class, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("customer", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}

sub update {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});
    my $params = { %$self };
    delete $params->{_authentication};

    $self->merge(Net::Simplify::SimplifyApi->send_api_request("customer", 'update', $params, $auth));
}


1;
