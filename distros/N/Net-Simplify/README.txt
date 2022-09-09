
                Perl SDK for Simplify Commerce


  What is it?
  ------------

  A Perl API to the Simplify Commerce payments platform.   If you have
  not already got an account sign up at https://www.simplify.com/commerce.


  Dependencies
  ------------

  Requires Perl 5 and the following modules:

      Carp
      Crypt::Mac::HMAC
      JSON
      Mozilla::CA
      MIME::Base64
      Math::Random::Secure
      REST::Client
      Time::HiRes
      URI::Encode


  Installation
  ------------

  To install:

      perl Makefile.PL
      make install


  Using the SDK
  --------------

  To run a payment though Simplify Commerce use the following
  script substituting your public and private API keys:

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

  For more examples see https://www.simplify.com/commerce/docs/sdk/perl.


  Version
  -------

  This is version 1.6.0 of the SDK.  For an up-to-date
  version check at https://www.simplify.com/commerce/docs/sdk/perl.

  Licensing
  ---------

  Please see LICENSE.txt for details.

  Documentation
  -------------

  API documentation is available in the doc directory in HTML.  For more
  detailed information on the API with examples visit the online 
  documentation at https://www.simplify.com/commerce/docs/sdk/perl.

  Support
  -------

  Please see https://www.simplify.com/commerce/support for information.
  
  Copyright
  ---------

  Copyright (c) 2013 - 2022 MasterCard International Incorporated
  All rights reserved.

