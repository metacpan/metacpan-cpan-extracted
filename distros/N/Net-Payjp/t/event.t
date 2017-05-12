#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 5;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->event, 'Net::Payjp::Event');


#List
can_ok($payjp->event, 'all');
#$res = $payjp->event->all(limit => 10, offset => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "created": 1442298026,
      "data": {
        "amount": 5000,
        "amount_refunded": 5000,
        "captured": true,
        "captured_at": 1442212986,
        "card": {
          "address_city": null,
          "address_line1": null,
          "address_line2": null,
          "address_state": null,
          "address_zip": null,
          "address_zip_check": "unchecked",
          "brand": "Visa",
          "country": null,
          "created": 1442212986,
          "customer": null,
          "cvc_check": "passed",
          "exp_month": 1,
          "exp_year": 2016,
          "fingerprint": "e1d8225886e3a7211127df751c86787f",
          "id": "car_f0984a6f68a730b7e1814ceabfe1",
          "last4": "4242",
          "name": null,
          "object": "card"
        },
        "created": 1442212986,
        "currency": "jpy",
        "customer": null,
        "description": "hogehoe",
        "expired_at": null,
        "failure_code": null,
        "failure_message": null,
        "id": "ch_bcb7776459913c743c20e9f9351d4",
        "livemode": false,
        "object": "charge",
        "paid": true,
        "refund_reason": null,
        "refunded": true,
        "subscription": null
      },
      "id": "evnt_8064917698aa417a3c86d292266",
      "livemode": false,
      "object": "event",
      "pending_webhooks": 1,
      "type": "charge.updated"
    }
  ],
  "has_more": true,
  "object": "list",
  "url": "/v1/events"
})));
is($res->object, 'list', 'got a list object back');


#Set evnt_id.
$payjp->id($res->{data}->[0]->{id});


#Retrieve
can_ok($payjp->event, 'retrieve');
#$res = $payjp->event->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "created": 1442288882,
  "data": {
    "cards": {
      "count": 0,
      "data": [],
      "has_more": false,
      "object": "list",
      "url": "/v1/customers/cus_a16c7b4df01168eb82557fe93de4/cards"
    },
    "created": 1441936720,
    "default_card": null,
    "description": "updated\n",
    "email": null,
    "id": "cus_a16c7b4df01168eb82557fe93de4",
    "livemode": false,
    "object": "customer",
    "subscriptions": {
      "count": 0,
      "data": [],
      "has_more": false,
      "object": "list",
      "url": "/v1/customers/cus_a16c7b4df01168eb82557fe93de4/subscriptions"
    }
  },
  "id": "evnt_54db4d63c7886256acdbc784ccf",
  "livemode": false,
  "object": "event",
  "pending_webhooks": 1,
  "type": "customer.updated"
})));
is($res->object, 'event', 'got a event object back');




