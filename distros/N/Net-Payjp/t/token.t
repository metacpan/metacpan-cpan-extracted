#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Net::Payjp;
use Test::More tests => 14;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->token, 'Net::Payjp::Token');
can_ok($payjp->token, qw(retrieve create tds_finish));
ok(!$payjp->token->can('all'));
ok(!$payjp->token->can('save'));
ok(!$payjp->token->can('delete'));

$Mock_resp->mock( content => sub { '{"id":"res1"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#Create
$Mock_req->mock( content => sub {
    my $p = $_[1];
    is($p, 'card%5Bnumber%5D=4242');
} );
my $token = $payjp->token;
my $res = $token->create(card => {number => '4242'});
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tokens');
is($res->id, 'res1');
is($token->id, 'res1');

#Retrieve
$token->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tokens/res1');

#tds_finish
$token->tds_finish;
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/tokens/res1/tds_finish');
