#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More tests => 15;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');
isa_ok($payjp->plan, 'Net::Payjp::Plan');
can_ok($payjp->plan, qw(retrieve create all save delete));

$Mock_resp->mock( content => sub { '{"id":"res1"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#Create
my $plan = $payjp->plan;
$plan->create();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans');
is($plan->id, 'res1');

#retrieve
$payjp->plan->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans/');

$plan->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans/res1');

#Update
$plan->save();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans/res1');

#Delete
$plan->delete;
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans/res1');

#List
$payjp->plan->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/plans?limit=3');

