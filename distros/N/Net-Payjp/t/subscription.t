#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More tests => 33;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');
isa_ok($payjp->subscription, 'Net::Payjp::Subscription');
can_ok($payjp->subscription, qw(retrieve create all save delete pause cancel resume));

$Mock_resp->mock( content => sub { '{"id":"res1"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#Create
my $subscription = $payjp->subscription;
my $res = $subscription->create(
    customer         => 'cus_id',
    plan             => 'pl_id',
);
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions');
is($res->id, 'res1');
is($subscription->id, 'res1');

#retrieve
$payjp->subscription->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/');

$subscription->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/res1');

#Update
$subscription->save();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/res1');

#Pause
$Mock_resp->mock( content => sub { '{"object":"subscription"}' } );
$subscription->pause;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/res1/pause');

$subscription->pause('req1');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req1/pause');
is($subscription->id, 'req1');

#Resume
$subscription->resume;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req1/resume');

$subscription->resume('req2');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req2/resume');
is($subscription->id, 'req2');

#Cancel
$subscription->cancel;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req2/cancel');

$subscription->cancel('req3');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req3/cancel');
is($subscription->id, 'req3');

#Delete
$subscription->delete;
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req3');

$subscription->delete(prorate => 'true');
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions/req3?prorate=true');

#List
$payjp->subscription->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/subscriptions?limit=3');

