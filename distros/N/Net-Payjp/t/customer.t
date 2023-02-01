#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');
my $customer = $payjp->customer;

isa_ok($payjp->customer, 'Net::Payjp::Customer');
can_ok($payjp->customer, qw(retrieve all create save delete card subscription));

$Mock_resp->mock( content => sub { '{"id":"id1","metadata":{"hoge":"fuga"}}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

is($customer->id, undef);
#Create
$Mock_req->mock( content => sub {
    my $p = $_[1];
    like($p, qr/description=test\+description/);
    like($p, qr/.+[&].+/);
    like($p, qr/metadata%5Bhoge%5D=fuga/);
} );
my $res = $customer->create(
    description    => 'test description.',
    'metadata[hoge]' => 'fuga'
);
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers');
is($res->metadata->{hoge}, 'fuga', 'got a customer metadata');
is($customer->id, 'id1');

#Retrieve
$customer->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id1');

#Update
$Mock_req->mock( content => sub {
    my $p = $_[1];
    is($p, 'email=test%40test.jp');
} );
$customer->save(email => 'test@test.jp');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id1');

#Delete
can_ok($payjp->customer, 'delete');
$Mock_resp->mock( content => sub { '{"deleted":true}' } );
ok($customer->delete->deleted);
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id1');

#All
$payjp->customer->all(limit => 2);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers?limit=2');

#Card
can_ok($payjp->customer, 'card');
my $card = $customer->card('id2');
is($card->cus_id, 'id2');
is($customer->cus_id, 'id2');

isa_ok($card, 'Net::Payjp::Customer::Card');
can_ok($card, 'create');
$Mock_resp->mock( content => sub { '{"id":"card_id1"}' } );
my $res_card = $card->create();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id2/cards');

#Retrieve card
can_ok($card, 'retrieve');
$card->retrieve($res_card->id);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id2/cards/card_id1');

#Update card
can_ok($card, 'save');
$card->save();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id2/cards/card_id1');

#Delete card
can_ok($card, 'delete');
$card->delete;
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id2/cards/card_id1');

#List card
can_ok($card, 'all');
$card->all(offset => 0);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id2/cards?offset=0');

#Retrieve subscription
can_ok($payjp->customer, 'subscription');
my $subscription = $payjp->customer->subscription($res->id);
is($subscription->cus_id, 'id1');
can_ok($subscription, 'retrieve');
$subscription->retrieve('sub_id1');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id1/subscriptions/sub_id1');

#List subscription
can_ok($subscription, 'all');
$subscription->all(offset => 0);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/customers/id1/subscriptions?offset=0');

done_testing();
