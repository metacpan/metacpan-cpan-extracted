#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Net::Payjp;
use Test::More tests => 11;

my $payjp = Net::Payjp->new(api_key => 'api_key');

isa_ok($payjp->three_d_secure_request, 'Net::Payjp::ThreeDSecureRequest');
can_ok($payjp->three_d_secure_request, qw(retrieve create all));

$Mock_resp->mock( content => sub { '{"id":"tdsr_xxx"}' } );
$Mock_resp->mock( code => sub {200}  );
$Mock_ua->mock( timeout => sub {} );
$Mock_ua->mock( default_header => sub {}  );

#Create
$Mock_req->mock( content => sub {
    my $p = $_[1];
    is($p, 'resource_id=car_xxxx');
} );
my $tds_request = $payjp->three_d_secure_request;
my $res = $tds_request->create(resource_id => 'car_xxxx');
is($Mock_req->{new_args}[1], 'POST');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/three_d_secure_requests');
is($res->id, 'tdsr_xxx');
is($tds_request->id, 'tdsr_xxx');

#Retrieve
$tds_request->retrieve;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/three_d_secure_requests/tdsr_xxx');

#tds_finish
$tds_request->all;
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'https://api.pay.jp/v1/three_d_secure_requests');
