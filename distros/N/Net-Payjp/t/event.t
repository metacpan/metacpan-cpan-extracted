#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More tests => 10;

use Net::Payjp;

my $payjp = Net::Payjp->new(api_key => 'api_key');
isa_ok($payjp->event, 'Net::Payjp::Event');
can_ok($payjp->event, qw(retrieve all));
ok(!$payjp->event->can('create'));
ok(!$payjp->event->can('save'));
ok(!$payjp->event->can('delete'));

$Mock_resp->mock( content => sub { '{"data":[{"id":"res1"}]}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#List
my $res = $payjp->event->all(limit => 10);
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/events?limit=10');

#Retrieve
my $event = $payjp->event;
$res = $event->retrieve($res->{data}->[0]->{id});
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/events/res1');
is($event->id, 'res1');
