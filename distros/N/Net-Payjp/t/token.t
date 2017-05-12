#!/usr/bin/perl

use strict;
use warnings;

use Net::Payjp;
use Test::More tests => 5;

my $api_key = 'sk_test_c62fade9d045b54cd76d7036';
my $payjp = Net::Payjp->new(api_key => $api_key);
my $res;


isa_ok($payjp->token, 'Net::Payjp::Token');


#Create
my $card = {
  number => '4242424242424242',
  cvc => "1234",
  exp_month => "02",
  exp_year =>"2020"
};
can_ok($payjp->token, 'create');
#$res = $payjp->token->create(
#  card => $card,
#);
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1442290383,
    "customer": null,
    "cvc_check": "passed",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_e3ccd4e0959f45e7c75bacc4be90",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1442290383,
  "id": "tok_5ca06b51685e001723a2c3b4aeb4",
  "livemode": false,
  "object": "token",
  "used": false
}
)));
is($res->object, 'token', 'got a token object back');


#Set tok_id.
$payjp->id($res->id);


#Retrieve
can_ok($payjp->token, 'retrieve');
#$res = $payjp->token->retrieve;
$res = $payjp->_to_object(JSON->new->decode(q(
{
  "card": {
    "address_city": null,
    "address_line1": null,
    "address_line2": null,
    "address_state": null,
    "address_zip": null,
    "address_zip_check": "unchecked",
    "brand": "Visa",
    "country": null,
    "created": 1442290383,
    "customer": null,
    "cvc_check": "passed",
    "exp_month": 2,
    "exp_year": 2020,
    "fingerprint": "e1d8225886e3a7211127df751c86787f",
    "id": "car_e3ccd4e0959f45e7c75bacc4be90",
    "last4": "4242",
    "name": null,
    "object": "card"
  },
  "created": 1442290383,
  "id": "tok_5ca06b51685e001723a2c3b4aeb4",
  "livemode": false,
  "object": "token",
  "used": true
}
)));
is($res->object, 'token', 'got a token object back');


