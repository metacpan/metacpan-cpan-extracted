#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->balance, 'Net::Payjp::Balance');
can_ok($payjp->balance, qw(retrieve all statement_urls));
ok(!$payjp->balance->can('create'));
ok(!$payjp->balance->can('save'));
ok(!$payjp->balance->can('delete'));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->balance->all(type => 'collecting');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/balances?type=collecting');
is($res->object, 'list');

#Set id.
$payjp->id('req1');

#Retrieve
$Mock_resp->mock( content => sub { '{"id":"req2"}' } );
my $balance = $payjp->balance;
is($balance->id, 'req1');
$balance->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/balances/req1');
is($balance->id, 'req2');
is($payjp->id, 'req1');

$Mock_req->mock( content => sub {
    my $p = $_[1];
    like($p, qr/platformer=true/);
} );
$balance->statement_urls(platformer => 'true');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/balances/req2/statement_urls');

done_testing();