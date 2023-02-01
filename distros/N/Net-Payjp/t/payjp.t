#!/usr/bin/perl

use strict;
use warnings;

use Test::Mock::LWP;
use Test::More;

use Net::Payjp;
use JSON;

use_ok('Net::Payjp');

my $payjp = Net::Payjp->new(api_key => 'api_key1');
is($payjp->{api_key}, 'api_key1', 'does not set by new()');
is($payjp->{api_base}, 'https://api.pay.jp', 'does not set by new()');
is($payjp->{id}, undef, 'does not set by new()');
is($payjp->{max_retry}, 0, 'does not set by new()');
is($payjp->{initial_delay}, 2, 'does not set by new()');
is($payjp->{max_delay}, 32, 'does not set by new()');

is($payjp->api_key, 'api_key1', 'does not set by api_key()');
is($payjp->api_key('api_key2'), 'api_key2', 'does not set by api_key()');
is($payjp->{api_key}, 'api_key2', 'does not get api_key');

is($payjp->api_base, 'https://api.pay.jp', 'does not set by api_base()');
is($payjp->api_base('test'), 'test', 'does not set by api_base()');
is($payjp->{api_base}, 'test', 'does not get api_base');

is($payjp->id('id1'), 'id1', 'does not set by id()');
is($payjp->{id}, 'id1', 'does not get id');

isa_ok($payjp->charge, 'Net::Payjp::Charge', 'is not object');
is($payjp->charge->{api_key}, 'api_key2', 'does not get property');
is($payjp->charge->{id}, 'id1', 'does not get property');
is($payjp->charge->{api_base}, 'https://api.pay.jp', 'does not get property');
is($payjp->charge(id => 'ignore')->{id}, 'id1', 'does not get property');

isa_ok($payjp->customer, 'Net::Payjp::Customer');
is($payjp->customer->{api_key}, 'api_key2');
is($payjp->customer->{id}, 'id1');
is($payjp->customer(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->subscription, 'Net::Payjp::Subscription');
is($payjp->subscription->{api_key}, 'api_key2');
is($payjp->subscription->{id}, 'id1');
is($payjp->subscription(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->transfer, 'Net::Payjp::Transfer');
is($payjp->transfer->{api_key}, 'api_key2');
is($payjp->transfer->{id}, 'id1');
is($payjp->transfer(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->transfer, 'Net::Payjp::Transfer');
is($payjp->transfer->{api_key}, 'api_key2');
is($payjp->transfer->{id}, 'id1');
is($payjp->transfer(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->token, 'Net::Payjp::Token');
is($payjp->token->{api_key}, 'api_key2');
is($payjp->token->{id}, 'id1');
is($payjp->token(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->event, 'Net::Payjp::Event');
is($payjp->event->{api_key}, 'api_key2');
is($payjp->event->{id}, 'id1');
is($payjp->event(id => 'ignore')->{id}, 'id1');

isa_ok($payjp->account, 'Net::Payjp::Account');
is($payjp->account->{api_key}, 'api_key2');

my $actual = $payjp->_to_object({
  object => 'test'
});
isa_ok($actual, 'Net::Payjp::Object');
is($actual->object, 'test');
is($actual->autoload, undef);

is_deeply($payjp->_api_param(
  param => {key => 'value'},
), {key => 'value'});

is_deeply($payjp->_api_param(
    param => {key => {nested => 'value'}},
), {'key[nested]' => 'value'});

# Test request/response with mock
$Mock_ua->mock( timeout => sub {is($_[1], 30)} );
$Mock_ua->mock( default_header => sub {
  my $self = shift;
  my %p = @_;
  is($p{'User-Agent'}, 'Payjp/v1 PerlBindings/'.$Net::Payjp::VERSION);
  my $ua = JSON->new->decode($p{'X-Payjp-Client-User-Agent'});
  is($ua->{'bindings_version'}, $Net::Payjp::VERSION);
  is($ua->{'lang_version'}, $]);
  is($ua->{'publisher'}, 'payjp');
  is($ua->{'uname'}, $^O);
  is($ua->{'lang'}, 'perl');
} );

## Check get request and if setting response to object
$Mock_resp->mock( content => sub {'{"id":"id3"}'} );
$Mock_resp->mock( code => sub {200} );
$Mock_req->mock( authorization_basic => sub {
  is($_[1], 'api_key2');
  is($_[2], '');
} );
my $resp = $payjp->_request(method => 'GET', url => 'test');
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'test');
isa_ok($resp, 'Net::Payjp::Object');
is($resp->id, 'id3');
is($payjp->{id}, 'id3');

$payjp->_request(url => 'test', param => {'k1'=>'v1'});
is($Mock_req->{new_args}[1], 'GET');
is($Mock_req->{new_args}[2], 'test?k1=v1');

## Check post request and no parameters
$Mock_req->mock( content => sub {
  my $p = $_[1];
  is($p, undef);
} );
$payjp->_request(method => 'POST', url => 'test');
is($Mock_req->{new_args}[1], 'POST');

## Check post request and parameters
$Mock_req->mock( content => sub {
  my $p = $_[1];
  is($p, 'k1=v1');
} );
$payjp->_request(method => 'POST', url => 'test', param => {'k1'=>'v1'});

## Check delete request and parameters
$payjp->_request(method => 'DELETE', url => 'test');
is($Mock_req->{new_args}[1], 'DELETE');

## Check 400 error response
$Mock_resp->mock( code => sub {400} );
$Mock_resp->mock( content => sub {'{"id":"id4"}'} );
$resp = $payjp->_request(url => 'test');
isa_ok($resp, 'Net::Payjp::Object');
is($resp->id, 'id4');
is($payjp->{id}, 'id3'); # not setting error value

## Check rate limit response without retry
my $count = 0;
$Mock_resp->mock( code => sub {
  $count += 1;
  return 429;
} );
$Mock_resp->mock(content => sub {'{"id":"id5"}'});
$payjp->_request(url => 'test');
is($count, 1);

## Check rate limit response with retry
my $charge = Net::Payjp->new(
  api_key => 'api_key2',
  max_retry => 2,
  initial_delay => 3,
  max_delay => 4,
  id => 'id3'
)->charge;
is($charge->{max_retry}, 2, 'does not set by new()');
is($charge->{initial_delay}, 3, 'does not set by new()');
is($charge->{max_delay}, 4, 'does not set by new()');

### ケース1：リトライ2回（合計3回）設定 → 全て400系（データ更新されず）
$count = 0;
$resp = $charge->all();
isa_ok($resp, 'Net::Payjp::Object');
is($count, 3);
is($resp->id, 'id5');
is($charge->{id}, 'id3');

### ケース2：リトライ2回（合計3回）設定 → 3回目成功（データ更新される）
$count = 0;
$Mock_resp->mock( code => sub {
  $count += 1;
  return $count == 2 ? 200 : 429;
} );
$resp = $charge->all();
is($count, 2);
is($resp->id, 'id5');
is($charge->{id}, 'id5');

## Check 500 error response
$Mock_resp->mock( code => sub {500} );
$Mock_resp->mock( message => sub {'message'} );
$resp= $payjp->_request(url => 'test');
isa_ok($resp, 'Net::Payjp::Object');
is_deeply($resp->error, {message=>'message', 'status_code'=>500});


is($payjp->_class_url, 'test/v1/payjps');
$payjp->id('id1');
is($payjp->_instance_url, 'test/v1/payjps/id1');

# 1000 / 2 + 1000 / 2 * Math.random()
my $got = $payjp->_get_delay_sec(retry => 0, init_sec => 1, max_sec => 2);
ok(0.5 <= $got);
ok($got <= 1);
## 1000 * 2 ^ 2 / 2 + ...
$got = $payjp->_get_delay_sec(retry => 2, init_sec => 1, max_sec => 2);
ok(1 <= $got);
ok($got <= 2);
# Calcurated range is 500-1000 but the larger end is limited to 600
$got = $payjp->_get_delay_sec(retry => 0, init_sec => 1, max_sec => 0.6);
ok(0.3 <= $got);
ok($got <= 0.6);

done_testing();
