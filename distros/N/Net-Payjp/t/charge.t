#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More tests => 17;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');
isa_ok($payjp->charge, 'Net::Payjp::Charge');
can_ok($payjp->charge, qw(retrieve create all save refund capture reauth tds_finish));
ok(!$payjp->event->can('delete'));

$Mock_resp->mock( content => sub { '{"id":"res1"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

$Mock_req->mock( content => sub {
    my $p = $_[1];
    is($p, 'refund_reason=reason1');
} );
$payjp->id('req1');
my $res = $payjp->charge->refund(refund_reason => 'reason1');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/charges/req1/refund');
is($res->id, 'res1');
is($payjp->id, 'req1');

$Mock_req->mock( content => sub {
    my $p = $_[1];
    is($p, 'amount=1000');
} );
$payjp->charge->capture(amount => 1000);
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/charges/req1/capture');

$payjp->charge->reauth();
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/charges/req1/reauth');

$payjp->charge->tds_finish;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/charges/req1/tds_finish');

#List
$payjp->charge->all(limit => 3);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/charges?limit=3');

