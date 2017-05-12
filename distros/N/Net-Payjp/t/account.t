#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 3;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);

isa_ok($payjp->account, 'Net::Payjp::Account');
can_ok($payjp->account, 'retrieve');
#my $res = $payjp->account->retrieve;
my $res = $payjp->_to_object(JSON->new->decode(q(
{
  "accounts_enabled": [
    "merchant",
    "customer"
  ],
  "created": 1439706600,
  "customer": {
    "cards": {
      "count": 1,
      "data": [
        {
          "address_city": "赤坂",
          "address_line1": "7-4",
          "address_line2": "203",
          "address_state": "港区",
          "address_zip": "1070050",
          "address_zip_check": "passed",
          "brand": "Visa",
          "country": "JP",
          "created": 1439706600,
          "cvc_check": "passed",
          "exp_month": 12,
          "exp_year": 2016,
          "fingerprint": "e1d8225886e3a7211127df751c86787f",
          "id": "car_99abf74cb5527ff68233a8b836dd",
          "last4": "4242",
          "livemode": true,
          "name": "Test Hodler",
          "object": "card"
        }
      ],
      "has_more": false,
      "object": "list",
      "url": "/v1/accounts/cards"
    },
    "created": 1439706600,
    "default_card": null,
    "description": "account customer",
    "email": null,
    "id": "acct_cus_7d03658e143dee2ef876b3e",
    "object": "customer"
  },
  "email": "liveaccount@mail.com",
  "id": "acct_8a27db83a7bf11a0c12b0c2833f",
  "merchant": {
    "bank_enabled": false,
    "brands_accepted": [
      "Visa",
      "MasterCard",
      "JCB",
      "American Express",
      "Diners Club",
      "Discover"
    ],
    "business_type": null,
    "charge_type": null,
    "contact_phone": null,
    "country": "JP",
    "created": 1439706600,
    "currencies_supported": [
      "jpy"
    ],
    "default_currency": "jpy",
    "details_submitted": false,
    "id": "acct_mch_21a96cb898ceb6db0932983",
    "livemode_activated_at": 0,
    "livemode_enabled": false,
    "object": "merchant",
    "product_detail": null,
    "product_name": null,
    "product_type": null,
    "site_published": null,
    "url": null
  },
  "object": "account"
}
)));
is($res->object, 'account', 'got a account object back');
