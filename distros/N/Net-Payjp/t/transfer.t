#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Net::Payjp;
use Test::More tests => 15;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->transfer, 'Net::Payjp::Transfer');
can_ok($payjp->transfer, qw(retrieve all charges));
ok(!$payjp->transfer->can('create'));
ok(!$payjp->transfer->can('save'));
ok(!$payjp->transfer->can('delete'));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->transfer->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/transfers?limit=3');
is($res->object, 'list');

#Set tr_id.
$payjp->id('req1');

#Retrieve
$Mock_resp->mock( content => sub { '{"id":"req2"}' } );
my $transfer = $payjp->transfer;
is($transfer->id, 'req1');
$transfer->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/transfers/req1');
is($transfer->id, 'req2');
is($payjp->id, 'req1');

#Charges
$payjp->transfer->charges(offset => 0);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/transfers/req1/charges?offset=0');
