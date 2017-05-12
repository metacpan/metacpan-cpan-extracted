
package Net::Simplify;

=head1 NAME

Net::Simplify - Simplify Commerce Payments API

=head1 SYNOPSIS

  use Net::Simplify;

  # Set global API keys
  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a payment
  my $payment = Net::Simplify::Payment->create({
          amount => 1200,
          currency => 'USD',
          description => 'test payment',
          card => {
             number => "5555555555554444",
             cvc => "123",
             expMonth => 12,
             expYear => 19
          },
          reference => 'P100'
  });

  printf "Payment %s %s\n", $payment->{id}, $payment->{paymentStatus};



  # Use an Authentication object to hold credentials
  my $auth = Net::Simplify::Authentication->create({
        public_key => 'YOUR PUBLIC KEY',
        private_key => 'YOUR PRIVATE_KEY'
  };

  # Create a payment using the $auth object
  my $payment2 = Net::Simplify::Payment->create({
          amount => 2400,
          currency => 'USD',
          description => 'test payment',
          card => {
             number => "5555555555554444",
             cvc => "123",
             expMonth => 12,
             expYear => 19
          },
          reference => 'P101'
  }, $auth);

  printf "Payment %s %s\n", $payment2->{id}, $payment2->{paymentStatus};

=head1 DESCRIPTION

The Simplify module provides a convenient way of accessing the Simplify API.  It allows global
authentication keys to be set and imports all of the Simplify packages.


=head2 GLOBAL VARIABLES

=head3 $Net::Simplify::public_key

The public key to be used for all API calls where an Authentication object is not passed.

=head3 $Net::Simplify::private_key

The private key to be used for all API calls where an Authentication object is not passed.

=head3 $Net::Simplify::user_agent

The user agent string to be sent with all requests.

=head1 SEE ALSO

L<Net::Simplify::AccessToken>,
L<Net::Simplify::ApiException>,
L<Net::Simplify::Authentication>,
L<Net::Simplify::AuthenticationException>,
L<Net::Simplify::Authorization>,
L<Net::Simplify::BadRequestException>,
L<Net::Simplify::CardToken>,
L<Net::Simplify::Chargeback>,
L<Net::Simplify::Constants>,
L<Net::Simplify::Coupon>,
L<Net::Simplify::Customer>,
L<Net::Simplify::Deposit>,
L<Net::Simplify::Event>,
L<Net::Simplify::Event>,
L<Net::Simplify::FieldError>,
L<Net::Simplify::FraudCheck>,
L<Net::Simplify::IllegalArgumentException>,
L<Net::Simplify::Invoice>,
L<Net::Simplify::InvoiceItem>,
L<Net::Simplify::Tax>,
L<Net::Simplify::TransactionReview>,
L<Net::Simplify::NotAllowedException>,
L<Net::Simplify::ObjectNotFoundException>,
L<Net::Simplify::Payment>,
L<Net::Simplify::Plan>,
L<Net::Simplify::Refund>,
L<Net::Simplify::Subscription>,
L<Net::Simplify::SystemException>,
L<Net::Simplify::Webhook>,
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

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Simplify::Constants;

$Net::Simplify::public_key = undef;
$Net::Simplify::private_key = undef;
$Net::Simplify::api_base_live_url = $Net::Simplify::Constants::API_BASE_LIVE_URL;
$Net::Simplify::api_base_sandbox_url = $Net::Simplify::Constants::API_BASE_SANDBOX_URL;
$Net::Simplify::oauth_base_url = $Net::Simplify::Constants::OAUTH_BASE_URL;
$Net::Simplify::user_agent = undef;

use Net::Simplify::Authentication;
use Net::Simplify::AccessToken;
use Net::Simplify::ApiException;
use Net::Simplify::IllegalArgumentException;
use Net::Simplify::AuthenticationException;
use Net::Simplify::ObjectNotFoundException;
use Net::Simplify::NotAllowedException;
use Net::Simplify::BadRequestException;
use Net::Simplify::SystemException;
use Net::Simplify::FieldError;
use Net::Simplify::SimplifyApi;
use Net::Simplify::Event;

use Net::Simplify::Authorization;
use Net::Simplify::CardToken;
use Net::Simplify::Chargeback;
use Net::Simplify::Constants;
use Net::Simplify::Coupon;
use Net::Simplify::Customer;
use Net::Simplify::DataToken;
use Net::Simplify::Deposit;
use Net::Simplify::FraudCheck;
use Net::Simplify::Invoice;
use Net::Simplify::InvoiceItem;
use Net::Simplify::Tax;
use Net::Simplify::Payment;
use Net::Simplify::Plan;
use Net::Simplify::Refund;
use Net::Simplify::Subscription;
use Net::Simplify::TransactionReview;
use Net::Simplify::Webhook;

1;
