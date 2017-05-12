#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 28;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->customer, 'Net::Payjp::Customer');


#Create
can_ok($payjp->customer, 'create');
#$res = $payjp->customer->create(
#  "description" => "test description.",
#);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "cards": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/cards"
  },
  "created": 1433127983,
  "default_card": null,
  "description": "test",
  "email": null,
  "id": "cus_121673955bd7aa144de5a8f6c262",
  "livemode": false,
  "object": "customer",
  "subscriptions": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/subscriptions"
  }
}
)));
is($res->object, 'customer', 'got a customer object back');


#Set cus_id.
$payjp->id($res->id);


#Retrieve
can_ok($payjp->customer, 'retrieve');
#$res = $payjp->customer->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "cards": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/cards"
  },
  "created": 1433127983,
  "default_card": null,
  "description": "test",
  "email": null,
  "id": "cus_121673955bd7aa144de5a8f6c262",
  "livemode": false,
  "object": "customer",
  "subscriptions": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/subscriptions"
  }
}
)));
is($res->object, 'customer', 'got a customer object back');


#Update
can_ok($payjp->customer, 'save');
#$res = $payjp->customer->save(email => 'test@test.jp');
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "cards": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/cards"
  },
  "created": 1433127983,
  "default_card": null,
  "description": "test",
  "email": "added@email.com",
  "id": "cus_121673955bd7aa144de5a8f6c262",
  "livemode": false,
  "object": "customer",
  "subscriptions": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/subscriptions"
  }
}
)));
is($res->object, 'customer', 'got a customer object back');


#Delete
can_ok($payjp->customer, 'delete');
#$res = $payjp->customer->delete;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "deleted": true,
  "id": "cus_121673955bd7aa144de5a8f6c262",
  "livemode": false
}
)));
ok($res->deleted, 'delete was successful');


#List
can_ok($payjp->customer, 'all');
#$res = $payjp->customer->all(limit => 2, offset => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "cards": {
        "count": 0,
        "data": [],
        "has_more": false,
        "object": "list",
        "url": "/v1/customers/cus_842e21be700d1c8156d9dac025f6/cards"
      },
      "created": 1433059905,
      "default_card": null,
      "description": "test",
      "email": null,
      "id": "cus_842e21be700d1c8156d9dac025f6",
      "livemode": false,
      "object": "customer",
      "subscriptions": {
        "count": 0,
        "data": [],
        "has_more": false,
        "object": "list",
        "url": "/v1/customers/cus_842e21be700d1c8156d9dac025f6/subscriptions"
      }
    }
  ],
  "has_more": true,
  "object": "list",
  "url": "/v1/customers"
}
)));
is($res->object, 'list', 'got a list object back');


#Create card
#$res = $payjp->customer->create(
#  "description" => "test card.",
#);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "cards": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/cards"
  },
  "created": 1433127983,
  "default_card": null,
  "description": "test",
  "email": null,
  "id": "cus_121673955bd7aa144de5a8f6c262",
  "livemode": false,
  "object": "customer",
  "subscriptions": {
    "count": 0,
    "data": [],
    "has_more": false,
    "object": "list",
    "url": "/v1/customers/cus_121673955bd7aa144de5a8f6c262/subscriptions"
  }
}
)));
can_ok($payjp->customer, 'card');
my $card = $payjp->customer->card($res->id);
isa_ok($card, 'Net::Payjp::Customer::Card');
can_ok($card, 'create');
#my $res_card = $card->create(
#  number => '4242424242424242',
#  exp_year => '2020',
#  exp_month => '02'
#);
my $res_card = $payjp->_to_object(JSON->new->decode(q(
{
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
  "id": "car_f7d9fa98594dc7c2e42bfcd641ff",
  "last4": "4242",
  "livemode": false,
  "name": null,
  "object": "card"
}
)));
is($res_card->object, 'card', 'got a card object back');


#Retrieve card
can_ok($card, 'retrieve');
#$res_card = $card->retrieve($res_card->id);
$res_card = $payjp->_to_object(JSON->new->decode(q(
{
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
  "id": "car_f7d9fa98594dc7c2e42bfcd641ff",
  "last4": "4242",
  "livemode": false,
  "name": null,
  "object": "card"
}
)));
is($res_card->object, 'card', 'got a card object back');


#Update card
can_ok($card, 'save');
#$res_card = $card->save(exp_year => "2026", exp_month => "05", name => 'test');
$res_card = $payjp->_to_object(JSON->new->decode(q(
{
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
  "exp_month": 12,
  "exp_year": 2026,
  "fingerprint": "e1d8225886e3a7211127df751c86787f",
  "id": "car_f7d9fa98594dc7c2e42bfcd641ff",
  "last4": "4242",
  "livemode": false,
  "name": null,
  "object": "card"
}
)));
is($res_card->object, 'card', 'got a card object back');


#Delete card
can_ok($card, 'delete');
#$res_card = $card->delete;
$res_card = $payjp->_to_object(JSON->new->decode(q(
{
  "deleted": true,
  "id": "car_f7d9fa98594dc7c2e42bfcd641ff",
  "livemode": false
}
)));
ok($res_card->deleted, 'delete was successful');


#List card
$card->create(
  number => '4242424242424242',
  exp_year => '2020',
  exp_month => '02'
);
can_ok($card, 'all');
#$res_card = $card->all(limit => 2, offset => 0);
$res_card = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
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
      "id": "car_f7d9fa98594dc7c2e42bfcd641ff",
      "last4": "4242",
      "livemode": false,
      "name": null,
      "object": "card"
    }
  ],
  "object": "list",  
  "has_more": true,
  "url": "/v1/customers/cus_4df4b5ed720933f4fb9e28857517/cards"
})));
is($res_card->object, 'list', 'got a list object back');


#Retrieve subscription
#my $pln_res = $payjp->plan->create(
#  amount => 500,
#  currency => "jpy",
#  interval => "month",
#  trial_days => 30,
#);
my $pln_res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 500,
  "billing_day": null,
  "created": 1433127983,
  "currency": "jpy",
  "id": "pln_45dd3268a18b2837d52861716260",
  "interval": "month",
  "livemode": false,
  "name": null,
  "object": "plan",
  "trial_days": 30
}
)));

#my $res_subscription = $payjp->subscription->create(
#  customer => $res->id,
#  plan => $pln_res->id
#);
my $res_subscription = $payjp->_to_object(JSON->new->decode(q(
{
  "canceled_at": null,
  "created": 1433127983,
  "current_period_end": 1435732422,
  "current_period_start": 1433140422,
  "customer": "cus_4df4b5ed720933f4fb9e28857517",
  "id": "sub_567a1e44562932ec1a7682d746e0",
  "livemode": false,
  "object": "subscription",
  "paused_at": null,
  "plan": {
    "amount": 1000,
    "billing_day": null,
    "created": 1432965397,
    "currency": "jpy",
    "id": "pln_9589006d14aad86aafeceac06b60",
    "interval": "month",
    "name": "test plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": null,
  "start": 1433140422,
  "status": "active",
  "trial_end": null,
  "trial_start": null
}
)));

can_ok($payjp->customer, 'subscription');
my $subscription = $payjp->customer->subscription($res->id);
can_ok($subscription, 'retrieve');
#my $res_sub = $subscription->retrieve($res_subscription->id);
my $res_sub = $payjp->_to_object(JSON->new->decode(q(
{
  "canceled_at": null,
  "created": 1433127983,
  "current_period_end": 1435732422,
  "current_period_start": 1433140422,
  "customer": "cus_4df4b5ed720933f4fb9e28857517",
  "id": "sub_567a1e44562932ec1a7682d746e0",
  "livemode": false,
  "object": "subscription",
  "paused_at": null,
  "plan": {
    "amount": 1000,
    "billing_day": null,
    "created": 1432965397,
    "currency": "jpy",
    "id": "pln_9589006d14aad86aafeceac06b60",
    "interval": "month",
    "name": "test plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": null,
  "start": 1433140422,
  "status": "active",
  "trial_end": null,
  "trial_start": null
}
)));
is($res_sub->object, 'subscription', 'got a subscription object back');


#List subscription
can_ok($subscription, 'all');
#$res_sub = $subscription->all(limit => 5, offset => 0);
$res_sub = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "canceled_at": null,
      "created": 1433127983,
      "current_period_end": 1435732422,
      "current_period_start": 1433140422,
      "customer": "cus_4df4b5ed720933f4fb9e28857517",
      "id": "sub_567a1e44562932ec1a7682d746e0",
      "livemode": false,
      "object": "subscription",
      "paused_at": null,
      "plan": {
        "amount": 1000,
        "billing_day": null,
        "created": 1432965397,
        "currency": "jpy",
        "id": "pln_9589006d14aad86aafeceac06b60",
        "interval": "month",
        "name": "test plan",
        "object": "plan",
        "trial_days": 0
      },
      "resumed_at": null,
      "start": 1433140422,
      "status": "active",
      "trial_end": null,
      "trial_start": null
    }
  ],  
  "has_more": true,
  "object": "list",
  "url": "/v1/customers/cus_4df4b5ed720933f4fb9e28857517/subscriptions"
}
)));
is($res_card->object, 'list', 'got a list object back');



