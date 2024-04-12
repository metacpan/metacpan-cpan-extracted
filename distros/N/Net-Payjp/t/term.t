#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->term, 'Net::Payjp::Term');
can_ok($payjp->term, qw(retrieve all));
ok(!$payjp->transfer->can('create'));
ok(!$payjp->transfer->can('save'));
ok(!$payjp->transfer->can('delete'));

$Mock_resp->mock( content => sub { '{"object":"list"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->term->all(since_start_at => 1);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/terms?since_start_at=1');
is($res->object, 'list');

#Set id.
$payjp->id('req1');

#Retrieve
$Mock_resp->mock( content => sub { '{"id":"req2"}' } );
my $term = $payjp->term;
is($term->id, 'req1');
$term->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/terms/req1');
is($term->id, 'req2');
is($payjp->id, 'req1');

done_testing();