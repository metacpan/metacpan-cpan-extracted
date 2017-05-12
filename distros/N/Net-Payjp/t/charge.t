#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 13;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->charge, 'Net::Payjp::Charge');


#Create
my $card = {
  number => '4242424242424242',
  exp_month => '02',
  exp_year => '2020',
  address_zip => '2020014'
};
can_ok($payjp->charge, 'create');
#$res = $payjp->charge->create(
#  card => $card,
#  amount => 3500,
#  currency => 'jpy',
#  description => 'test description.',
#);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 3500,
  "amount_refunded": 0,
  "captured": true,
  "captured_at": 1433127983,
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1433127983,
    "cvc_check": "unchecked",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_d0e44730f83b0a19ba6caee04160",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1433127983,
  "currency": "jpy",
  "customer": null,
  "description": null,
  "expired_at": null,
  "failure_code": null,
  "failure_message": null,
  "fee": 0,
  "id": "ch_fa990a4c10672a93053a774730b0a",
  "livemode": false,
  "object": "charge",
  "paid": true,
  "refund_reason": null,
  "refunded": false,
  "subscription": null
}
)));
is($res->object, 'charge', 'got a charge object back');


#Set ch_id.
$payjp->id($res->id);


#Retrieve
can_ok($payjp->charge, 'retrieve');
#$res = $payjp->charge->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 3500,
  "amount_refunded": 0,
  "captured": true,
  "captured_at": 1433127983,
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1433127983,
    "cvc_check": "unchecked",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_d0e44730f83b0a19ba6caee04160",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1433127983,
  "currency": "jpy",
  "customer": null,
  "description": null,
  "expired_at": null,
  "failure_code": null,
  "failure_message": null,
  "id": "ch_fa990a4c10672a93053a774730b0a",
  "livemode": false,
  "object": "charge",
  "paid": true,
  "refund_reason": null,
  "refunded": false,
  "subscription": null
}
)));
is($res->object, 'charge', 'got a charge object back');


#Update
can_ok($payjp->charge, 'save');
#$res = $payjp->charge->save(description => 'update description.');
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 3500,
  "amount_refunded": 0,
  "captured": true,
  "captured_at": 1433127983,
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1433127983,
    "cvc_check": "unchecked",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_d0e44730f83b0a19ba6caee04160",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1433127983,
  "currency": "jpy",
  "customer": null,
  "description": "Updated",
  "expired_at": null,
  "failure_code": null,
  "failure_message": null,
  "id": "ch_fa990a4c10672a93053a774730b0a",
  "livemode": false,
  "object": "charge",
  "paid": true,
  "refund_reason": null,
  "refunded": false,
  "subscription": null
}
)));
is($res->object, 'charge', 'got a charge object back');


#Refund
can_ok($payjp->charge, 'refund');
#$res = $payjp->charge->refund(amount => 1000, refund_reason => 'refund test.');
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 3500,
  "amount_refunded": 3500,
  "captured": true,
  "captured_at": 1433127983,
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1433127983,
    "cvc_check": "unchecked",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_d0e44730f83b0a19ba6caee04160",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1433127983,
  "currency": "jpy",
  "customer": null,
  "description": "Updated",
  "expired_at": null,
  "failure_code": null,
  "failure_message": null,
  "id": "ch_fa990a4c10672a93053a774730b0a",
  "livemode": false,
  "object": "charge",
  "paid": true,
  "refund_reason": null,
  "refunded": true,
  "subscription": null
}
)));
is($res->object, 'charge', 'got a charge object back');


#Capture
#$res = $payjp->charge->create(
#  card => $card,
#  amount => 3500,
#  currency => 'jpy',
#  capture => 'false'
#);
#$payjp->id($res->id);
can_ok($payjp->charge, 'capture');
#$res = $payjp->charge->capture(amount => 2000);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 3500,
  "amount_refunded": 0,
  "captured": true,
  "captured_at": 1433128911,
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1433127983,
    "cvc_check": "unchecked",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_8eeadf285ef2c6da507eb1aebc93",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1433127983,
  "currency": "jpy",
  "customer": null,
  "description": null,
  "expired_at": 1433429999,
  "failure_code": null,
  "failure_message": null,
  "id": "ch_cce2fce62e9cb5632b3d38b0b1621",
  "livemode": false,
  "object": "charge",
  "paid": true,
  "refund_reason": null,
  "refunded": false,
  "subscription": null
}
)));
is($res->object, 'charge', 'got a charge object back');


#List
can_ok($payjp->charge, 'all');
#$res = $payjp->charge->all("limit" => 2, "offset" => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "amount": 1000,
      "amount_refunded": 0,
      "captured": true,     
      "captured_at": 1432965397,
      "card": {
        "address_city": "\u8d64\u5742",
        "address_line1": "7-4",
        "address_line2": "203",
        "address_state": "\u6e2f\u533a",
        "address_zip": "1070050",
        "address_zip_check": "passed",
        "brand": "Visa",
        "country": "JP",
        "created": 1432965397,
        "cvc_check": "passed",
        "exp_month": 12,
        "exp_year": 2016,
        "fingerprint": "e1d8225886e3a7211127df751c86787f",
        "id": "car_7a79b41fed704317ec0deb4ebf93",
        "last4": "4242",
        "name": "Test Hodler",
        "object": "card"
      },
      "created": 1432965397,
      "currency": "jpy",
      "customer": "cus_67fab69c14d8888bba941ae2009b",
      "description": "test charge",
      "expired_at": null,
      "failure_code": null,
      "failure_message": null,
      "id": "ch_6421ddf0e12a5e5641d7426f2a2c9",
      "livemode": false,
      "object": "charge",
      "paid": true,
      "refund_reason": null,
      "refunded": false,
      "subscription": null
    }
  ],
  "has_more": true,
  "object": "list",
  "url": "/v1/charges"
}
)));
is($res->object, 'list', 'got a list object back');


