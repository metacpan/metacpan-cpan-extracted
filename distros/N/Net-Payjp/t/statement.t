#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->statement, 'Net::Payjp::Statement');
can_ok($payjp->statement, qw(retrieve all statement_urls));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->statement->all(owner => 'merchant');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/statements?owner=merchant');
is($res->object, 'list');

#Retrieve
my $statement = $payjp->statement;
$statement->retrieve('req1');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/statements/req1');
is($statement->id, 'req1');

$Mock_req->mock( content => sub {
    my $p = $_[1];
    like($p, qr/platformer=true/);
} );
$statement->statement_urls(platformer => 'true');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/statements/req1/statement_urls');

done_testing();
