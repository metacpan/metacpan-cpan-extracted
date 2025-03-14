package Net::Simplify::CardToken;

=head1 NAME

Net::Simplify::CardToken - A Simplify Commerce CardToken object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new CardToken.
  my $card_token = Net::Simplify::CardToken->create{ {...});

  # Retrieve a CardToken given its ID.
  my $card_token = Net::Simplify::CardToken->find('a7e41');

  # Update existing CardToken.
  my $card_token = Net::Simplify::CardToken->find('a7e41');
  $card_token->{PROPERTY} = "NEW VALUE";
  $card_token->update();

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::CardToken> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4

=item authenticatePayer

Set as true to create CardToken for EMV 3DS transaction. [default: false] 

=item callback

The URL callback for the cardtoken 



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

Postal code of the cardholder. The postal code size is between 5 and 9 in length and only contain numbers or letters. [max length: 32] 

=item card.cvc

CVC security code of the card. This is the code on the back of the card. Example: 123 

=item card.expMonth

Expiration month of the card. Format is MM. Example: January = 01 [min value: 1, max value: 12] 

=item card.expYear

Expiration year of the card. Format is YY. Example: 2013 = 13 [min value: 0, max value: 99] 

=item card.name

Name as appears on the card. [max length: 50, min length: 2] 

=item card.number

Card number as it appears on the card. [max length: 19, min length: 13] 

=item key

Key used to create the card token. 



=item secure3DRequestData.amount

Amount of the subsequent transaction in the smallest unit of your currency. Example: 100 = $1.00 (B<required>) 

=item secure3DRequestData.authOnly

Specifies if the subsequent transaction is going to be a Payment or an Authorization (to be Captured later). If false or not specified, it refers to a Payment, otherwise it refers to an Authorization. 

=item secure3DRequestData.currency

Currency code (ISO-4217). Must match the currency associated with your account. (B<required>) 

=item secure3DRequestData.description

A description of the transaction. [max length: 256] 

=item secure3DRequestData.id

3D Secure data ID. 

=item source

Card Token Source [default: API] 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::CardToken> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 update()

Update C<Net::Simplify::CardToken> object.
The properties that can be updated are:

=over 4


=item C<device.browser>

The User-Agent header of the browser the customer used to place the order (B<required>) 

=item C<device.ipAddress>

The IP address of the device used by the payer, in nnn.nnn.nnn.nnn format. (B<required>) 

=item C<device.language>

The language supported for the payer's browser as defined in IETF BCP47. 

=item C<device.screenHeight>

The total height of the payer's browser screen in pixels. 

=item C<device.screenWidth>

The total width of the payer's browser screen in pixels. 

=item C<device.timeZone>

The timezone of the device used by the payer, in Zone ID format. Example: "Europe/Dublin" (B<required>) 


=item C<key>

The public key of the merchant to be used for the token 

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
    my $result = Net::Simplify::SimplifyApi->send_api_request("cardToken", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("cardToken", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}

sub update {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});
    my $params = { %$self };
    delete $params->{_authentication};

    $self->merge(Net::Simplify::SimplifyApi->send_api_request("cardToken", 'update', $params, $auth));
}


1;
