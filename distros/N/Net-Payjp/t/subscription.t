#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 17;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->subscription, 'Net::Payjp::Subscription');


#Create
#my $cus_res = $payjp->customer->create;
my $cus_res = $payjp->_to_object(JSON->new->decode(q(
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

can_ok($payjp->subscription, 'create');
#$res = $payjp->subscription->create(
#  customer => $cus_res->id,
#  plan => $pln_res->id
#);
$res = $payjp->_to_object(JSON->new->decode(q(
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
is($res->object, 'subscription', 'got a subscription object back');


#Set sub_id.
$payjp->id($res->id);


#retrieve
can_ok($payjp->subscription, 'retrieve');
#$res = $payjp->subscription->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
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
})));
is($res->object, 'subscription', 'got a subscription object back');


#Update
can_ok($payjp->subscription, 'save');
#$res = $payjp->subscription->save;
$res = $payjp->_to_object(JSON->new->decode(q(
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
    "amount": 500,    
    "billing_day": null,
    "created": 1433127983,
    "currency": "jpy",
    "id": "pln_68e6a67f582462c223ca693bc549",
    "interval": "week",
    "name": "weekly_plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": null,
  "start": 1433140422,
  "status": "trial",
  "trial_end": 1473911903,
  "trial_start": 1433140922
}
)));
is($res->object, 'subscription', 'got a subscription object back');


#Pause
can_ok($payjp->subscription, 'pause');
#$res = $payjp->subscription->pause;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "canceled_at": null,
  "created": 1432965397,
  "current_period_end": 1435643801,
  "current_period_start": 1432965401,
  "customer": "cus_2498ea9cb54644f4516a9bf6dc78",
  "id": "sub_f9fb5ef2507b46c00a1a84c47bed",
  "livemode": false,
  "object": "subscription",
  "paused_at": 1433141463,
  "plan": {
    "amount": 1000,    
    "billing_day": null,
    "created": 1432965397,
    "currency": "jpy",
    "id": "pln_acfbc08ae710da03ac2a3fcb2334",
    "interval": "month",
    "name": "test plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": null,
  "start": 1432965401,
  "status": "paused",
  "trial_end": null,
  "trial_start": null
}
)));
is($res->object, 'subscription', 'got a subscription object back');


#Resume
can_ok($payjp->subscription, 'resume');
#$res = $payjp->subscription->resume;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "canceled_at": null,
  "created": 1432965397,
  "current_period_end": 1435733621,
  "current_period_start": 1433141621,
  "customer": "cus_2498ea9cb54644f4516a9bf6dc78",
  "id": "sub_f9fb5ef2507b46c00a1a84c47bed",
  "livemode": false,
  "object": "subscription",
  "paused_at": null,
  "plan": {
    "amount": 1000,    
    "billing_day": null,
    "created": 1432965397,
    "currency": "jpy",
    "id": "pln_acfbc08ae710da03ac2a3fcb2334",
    "interval": "month",
    "name": "test plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": 1433141621,
  "start": 1433141621,
  "status": "active",
  "trial_end": null,
  "trial_start": null
}
)));
is($res->object, 'subscription', 'got a subscription object back');


#Cancel
can_ok($payjp->subscription, 'cancel');
#$res = $payjp->subscription->cancel;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "canceled_at": 1433141780,
  "created": 1432965397,
  "current_period_end": 1435643801,
  "current_period_start": 1432965401,
  "customer": "cus_d43eb7c419c0da28ca0fd414108e",
  "id": "sub_19f6a2123363b514a743d1334109",
  "livemode": false,
  "object": "subscription",
  "paused_at": null,
  "plan": {
    "amount": 1000,
    "billing_day": null,
    "created": 1432965397,
    "currency": "jpy",
    "id": "pln_01b0370fb0918777b952257302d5",
    "interval": "month",
    "name": "test plan",
    "object": "plan",
    "trial_days": 0
  },
  "resumed_at": null,
  "start": 1432965401,
  "status": "canceled",
  "trial_end": null,
  "trial_start": null
}
)));
is($res->object, 'subscription', 'got a subscription object back');


#Delete
can_ok($payjp->subscription, 'delete');
#$res = $payjp->subscription->delete;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "deleted": true,
  "id": "sub_19f6a2123363b514a743d1334109",
  "livemode": false
}
)));
ok($res->deleted, 'delete was successful');


#List
can_ok($payjp->subscription, 'all');
#$res = $payjp->subscription->all(limit => 3, offset => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "canceled_at": null,
      "created": 1432965397,
      "current_period_end": 1435643801,
      "current_period_start": 1432965401,
      "customer": "cus_ca2676897435d6476c4f6205a6f5",
      "id": "sub_80ac5ef1c0073a3e443a7d7deb93",
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
      "start": 1432965401,
      "status": "active",
      "trial_end": null,
      "trial_start": null
    }
  ],
  "has_more": true,
  "object": "list",
  "url": "/v1/subscriptions"
}
)));
is($res->object, 'list', 'got a list object back');

