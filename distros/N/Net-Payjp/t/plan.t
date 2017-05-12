#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 11;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->plan, 'Net::Payjp::Plan');


#Create
can_ok($payjp->plan, 'create');
#$res = $payjp->plan->create(
#  amount => 500,
#  currency => "jpy",
#  interval => "month",
#  trial_days => 30,
#  name => 'test_plan'
#);
$res = $payjp->_to_object(JSON->new->decode(q(
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
is($res->object, 'plan', 'got a plan object back');


#Set pln_id.
$payjp->id($res->id);


#Retrieve
can_ok($payjp->plan, 'retrieve');
#$res = $payjp->plan->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
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
is($res->object, 'plan', 'got a plan object back');


#Update
can_ok($payjp->plan, 'save');
#$res = $payjp->plan->save(name => 'update plan');
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "amount": 500,
  "billing_day": null,
  "created": 1433127983,
  "currency": "jpy",
  "id": "pln_45dd3268a18b2837d52861716260",
  "interval": "month",
  "livemode": false,
  "name": "NewPlan",
  "object": "plan",
  "trial_days": 30
})));
is($res->object, 'plan', 'got a plan object back');


#Delete
can_ok($payjp->plan, 'delete');
#$res = $payjp->plan->delete;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "deleted": true,
  "id": "pln_45dd3268a18b2837d52861716260",
  "livemode": false
}
)));
ok($res->deleted, 'delete was successful');


#List
can_ok($payjp->plan, 'all');
#$res = $payjp->plan->all("limit" => 5, "offset" => 0);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "count": 3,
  "data": [
    {
      "amount": 1000,
      "billing_day": null,
      "created": 1432965397,
      "currency": "jpy",
      "id": "pln_acfbc08ae710da03ac2a3fcb2334",
      "interval": "month",
      "livemode": false,
      "name": "test plan",
      "object": "plan",
      "trial_days": 0
    }
  ],
  "has_more": true,
  "object": "list",
  "url": "/v1/plans"
}
)));
is($res->object, 'list', 'got a list object back');

