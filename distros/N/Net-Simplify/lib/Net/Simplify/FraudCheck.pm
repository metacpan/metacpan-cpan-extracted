package Net::Simplify::FraudCheck;

=head1 NAME

Net::Simplify::FraudCheck - A Simplify Commerce FraudCheck object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new FraudCheck.
  my $fraud_check = Net::Simplify::FraudCheck->create{ {...});

  # Retrieve a FraudCheck given its ID.
  my $fraud_check = Net::Simplify::FraudCheck->find('a7e41');

  # Update existing FraudCheck.
  my $fraud_check = Net::Simplify::FraudCheck->find('a7e41');
  $fraud_check->{PROPERTY} = "NEW VALUE";
  $fraud_check->update();

  # Retrieve a list of objects
  my $fraud_checks = Net::Simplify::FraudCheck->list({max => 10});
  foreach my $v ($fraud_checks->list) {
      # ...
  }

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::FraudCheck> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4

=item amount

Amount of the transaction to be checked for fraud (in the smallest unit of your currency). Example: 100 = $1.00. This field is required if using “full” or “advanced” mode. 



=item card.addressCity

City of the cardholder. [max length: 50, min length: 2] 

=item card.addressCountry

Country code (ISO-3166-1-alpha-2 code) of residence of the cardholder. [max length: 2, min length: 2] 

=item card.addressLine1

Address of the cardholder. [max length: 255] 

=item card.addressLine2

Address of the cardholder if needed. [max length: 255] 

=item card.addressState

State of residence of the cardholder. State abbreviations should be used. [max length: 255] 

=item card.addressZip

Postal code of the cardholder. The postal code size is between 5 and 9 characters in length and only contains numbers or letters. [max length: 32] 

=item card.cvc

CVC security code of the card. This is the code on the back of the card. Example: 123 

=item card.expMonth

Expiration month of the card. Format is MM. Example: January = 01 [min value: 1, max value: 12] 

=item card.expYear

Expiration year of the card. Format is YY. Example: 2013 = 13 [min value: 0, max value: 99] 

=item card.name

Name as it appears on the card. [max length: 50, min length: 2] 

=item card.number

Card number as it appears on the card. [max length: 19, min length: 13] 

=item currency

Currency code (ISO-4217) for the transaction to be checked for fraud. This field is required if using “full” or “advanced” mode. 

=item description

- Description of the fraud check. [max length: 255] 

=item ipAddress

IP Address of the customer for which the fraud check is to be done. [max length: 45] 

=item mode

Fraud check mode.  “simple” only does an AVS and CVC check; “advanced” does a complete fraud check, running the input against the set up rules. [valid values: simple, advanced, full, SIMPLE, ADVANCED, FULL] (B<required>) 

=item sessionId

Session ID used during data collection. [max length: 255] 

=item token

Card token representing card details for the card to be checked. [max length: 255] 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 list(%criteria, $auth)

Retrieve a list of C<Net::Simplify::FraudCheck> objects.  The parameters are:

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

=item C<amount>

=item C<dateCreated>

=item C<fraudResult>


=back




=back

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::FraudCheck> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 update()

Update C<Net::Simplify::FraudCheck> object.
The properties that can be updated are:

=over 4



=item C<integratorAuthCode>

Authorization code for the transaction. [max length: 255] 

=item C<integratorAvsAddressResponse>

AVS address response. [max length: 255] 

=item C<integratorAvsZipResponse>

AVS zip response. [max length: 255] 

=item C<integratorCvcResponse>

CVC response. [max length: 255] 

=item C<integratorDeclineReason>

Reason for the decline if applicable. [max length: 255] 

=item C<integratorTransactionRef>

Reference id for the transaction. [max length: 255] (B<required>) 

=item C<integratorTransactionStatus>

Status of the transaction, valid values are "APPROVED", "DECLINED", "SETTLED", "REFUNDED" or "VOIDED". 

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
    my $result = Net::Simplify::SimplifyApi->send_api_request("fraudCheck", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub list {
    my ($class, $criteria, $auth) = @_;
   
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("fraudCheck", 'list', $criteria, $auth);

    Net::Simplify::DomainList->new($result, $class, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("fraudCheck", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}

sub update {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});
    my $params = { %$self };
    delete $params->{_authentication};

    $self->merge(Net::Simplify::SimplifyApi->send_api_request("fraudCheck", 'update', $params, $auth));
}


1;
