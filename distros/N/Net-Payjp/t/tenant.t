#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Net::Payjp;
use Test::More tests => 16;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->tenant, 'Net::Payjp::Tenant');
can_ok($payjp->tenant, qw(retrieve all create save delete application_urls));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->tenant->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants?limit=3');
is($res->object, 'list');

#Retrieve
my $tenant = $payjp->tenant;
$tenant->retrieve('req1');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants/req1');
is($tenant->id, 'req1');

#Create
$payjp->tenant->create(hoge => 'fuga');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants');

#Update
$tenant->save(hoge => 'fuga');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants/req1');

#Delete
$tenant->delete(hoge => 'fuga');
is($Mock_req->{new_args}[1], 'DELETE');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants/req1');

#Application
$tenant->application_urls;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tenants/req1/application_urls');
