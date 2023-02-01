#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More tests => 11;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->account, 'Net::Payjp::Account');
can_ok($payjp->account, 'retrieve');
ok(!$payjp->account->can('create'));
ok(!$payjp->account->can('save'));
ok(!$payjp->account->can('all'));
ok(!$payjp->account->can('delete'));

$Mock_resp->mock( content => sub { '{"id":"res1"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

my $account = $payjp->account;
my $res = $account->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/accounts');
is($res->id, 'res1');
is($account->id, 'res1');
is($payjp->id, undef);
