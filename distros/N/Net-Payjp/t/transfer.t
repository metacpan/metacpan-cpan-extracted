#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 7;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->transfer, 'Net::Payjp::Transfer');


#List
can_ok($payjp->transfer, 'all');
#$res = $payjp->transfer->all("limit" => 3, offset => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 1,
  "data": [
    {
      "amount": 1000,
      "carried_balance": null,
      "charges": {
        "count": 1,
        "data": [
          {
            "amount": 1000,
            "amount_refunded": 0,
            "captured": true,
            "captured_at": 1441706750,
            "card": {
              "address_city": null,
              "address_line1": null,
              "address_line2": null,
              "address_state": null,
              "address_zip": null,
              "address_zip_check": "unchecked",
              "brand": "Visa",
              "country": null,
              "created": 1441706750,
              "cvc_check": "unchecked",
              "exp_month": 5,
              "exp_year": 2018,
              "fingerprint": "e1d8225886e3a7211127df751c86787f",
              "id": "car_93e59e9a9714134ef639865e2b9e",
              "last4": "4242",
              "name": null,
              "object": "card"
            },
            "created": 1441706750,
            "currency": "jpy",
            "customer": "cus_b92b879e60f62b532d6756ae12af",
            "description": null,
            "expired_at": null,
            "failure_code": null,
            "failure_message": null,
            "id": "ch_60baaf2dc8f3e35684ebe2031a6e0",
            "object": "charge",
            "paid": true,
            "refund_reason": null,
            "refunded": false,
            "subscription": null
          }
        ],
        "has_more": false,
        "object": "list",
        "url": "/v1/transfers/tr_8f0c0fe2c9f8a47f9d18f03959ba1/charges"
      },
      "created": 1438354800,
      "currency": "jpy",
      "description": null,
      "id": "tr_8f0c0fe2c9f8a47f9d18f03959ba1",
      "livemode": false,
      "object": "transfer",
      "scheduled_date": "2015-09-16",
      "status": "pending",
      "summary": {
        "charge_count": 1,
        "charge_fee": 0,
        "charge_gross": 1000,
        "net": 1000,
        "refund_amount": 0,
        "refund_count": 0
      },
      "term_end": 1439650800,
      "term_start": 1438354800,
      "transfer_amount": null,
      "transfer_date": null
    }
  ],
  "has_more": false,
  "object": "list",
  "url": "/v1/transfers"
}
)));
is($res->object, 'list', 'got a list object back');


#Set tr_id.
$payjp->id($res->{data}->[0]->{id});


#Retrieve
can_ok($payjp->transfer, 'retrieve');
#$res = $payjp->transfer->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 1000,
  "carried_balance": null,
  "charges": {
    "count": 1,
    "data": [
      {
        "amount": 1000,
        "amount_refunded": 0,
        "captured": true,
        "captured_at": 1441706750,
        "card": {
          "address_city": null,
          "address_line1": null,
          "address_line2": null,
          "address_state": null,
          "address_zip": null,
          "address_zip_check": "unchecked",
          "brand": "Visa",
          "country": null,
          "created": 1441706750,
          "cvc_check": "unchecked",
          "exp_month": 5,
          "exp_year": 2018,
          "fingerprint": "e1d8225886e3a7211127df751c86787f",
          "id": "car_93e59e9a9714134ef639865e2b9e",
          "last4": "4242",
          "name": null,
          "object": "card"
        },
        "created": 1441706750,
        "currency": "jpy",
        "customer": "cus_b92b879e60f62b532d6756ae12af",
        "description": null,
        "expired_at": null,
        "failure_code": null,
        "failure_message": null,
        "id": "ch_60baaf2dc8f3e35684ebe2031a6e0",
        "object": "charge",
        "paid": true,
        "refund_reason": null,
        "refunded": false,
        "subscription": null
      }
    ],
    "has_more": false,
    "object": "list",
    "url": "/v1/transfers/tr_8f0c0fe2c9f8a47f9d18f03959ba1/charges"
  },
  "created": 1438354800,
  "currency": "jpy",
  "description": null,
  "id": "tr_8f0c0fe2c9f8a47f9d18f03959ba1",
  "livemode": false,
  "object": "transfer",
  "scheduled_date": "2015-09-16",
  "status": "pending",
  "summary": {
    "charge_count": 1,
    "charge_fee": 0,
    "charge_gross": 1000,
    "net": 1000,
    "refund_amount": 0,
    "refund_count": 0
  },
  "term_end": 1439650800,
  "term_start": 1438354800,
  "transfer_amount": null,
  "transfer_date": null
}
)));
is($res->object, 'transfer', 'got a transfer object back');


#Charges
can_ok($payjp->transfer, 'charges');
#$res = $payjp->transfer->charges(
#  limit => 3, 
#  offset => 0
#);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 1,
  "data": [
    {
      "amount": 1000,
      "amount_refunded": 0,
      "captured": true,
      "captured_at": 1441706750,
      "card": {
        "address_city": null,
        "address_line1": null,
        "address_line2": null,
        "address_state": null,
        "address_zip": null,
        "address_zip_check": "unchecked",
        "brand": "Visa",
        "country": null,
        "created": 1441706750,
        "customer": "cus_b92b879e60f62b532d6756ae12af",
        "cvc_check": "unchecked",
        "exp_month": 5,
        "exp_year": 2018,
        "fingerprint": "e1d8225886e3a7211127df751c86787f",
        "id": "car_93e59e9a9714134ef639865e2b9e",
        "last4": "4242",
        "name": null,
        "object": "card"
      },
      "created": 1441706750,
      "currency": "jpy",
      "customer": "cus_b92b879e60f62b532d6756ae12af",
      "description": null,
      "expired_at": null,
      "failure_code": null,
      "failure_message": null,
      "id": "ch_60baaf2dc8f3e35684ebe2031a6e0",
      "livemode": false,
      "object": "charge",
      "paid": true,
      "refund_reason": null,
      "refunded": false,
      "subscription": null
    }
  ],
  "has_more": false,
  "object": "list",
  "url": "/v1/transfers/tr_8f0c0fe2c9f8a47f9d18f03959ba1/charges"
}
)));
is($res->object, 'list', 'got a list object back');


