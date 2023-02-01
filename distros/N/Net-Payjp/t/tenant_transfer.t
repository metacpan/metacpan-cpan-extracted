#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Net::Payjp;
use Test::More tests => 15;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->tenant_transfer, 'Net::Payjp::TenantTransfer');
can_ok($payjp->tenant_transfer, qw(retrieve all charges));
ok(!$payjp->tenant_transfer->can('create'));
ok(!$payjp->tenant_transfer->can('save'));
ok(!$payjp->tenant_transfer->can('delete'));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->tenant_transfer->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenant_transfers?limit=3');
is($res->object, 'list');

#Retrieve
$payjp->id('req1');

$Mock_resp->mock( content => sub { '{"id":"req2"}' } );
my $transfer = $payjp->tenant_transfer;
is($transfer->id, 'req1');
$transfer->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenant_transfers/req1');
is($transfer->id, 'req2');
is($payjp->id, 'req1');

#Charges
$payjp->tenant_transfer->charges(offset => 0);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenant_transfers/req1/charges?offset=0');
