#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 19;
use Test::Exception;
use Net::DNS::Resolver;
use Test::Mock::Net::Server::Mail;

my $s = Test::Mock::Net::Server::Mail->new(
  support_pipelining => 0,
);
$s->start_ok("start SMTP mock with PIPELINING disabled");

use_ok('Net::SMTP::Verify');
my $v = Net::SMTP::Verify->new(
  host => $s->bind_address,
  port => $s->port,
  logging_callback => sub { diag(shift) },
);

isa_ok( $v, 'Net::SMTP::Verify');

my $r;
lives_ok {
  $r = $v->check(100000, 'goodsender@gooddomain.tld', 'rcpt1@gooddomain.tld', 'rcpt2@gooddomain.tld', 'rcpt3@gooddomain.tld');
} 'check mail address';
cmp_ok( $r->is_all_success, 'eq', 1, 'must be successfull');

$s->stop_ok;

$s = Test::Mock::Net::Server::Mail->new;
$s->start_ok('start SMTP mock with PIPELINING');
$v->port( $s->port );

lives_ok {
  $r = $v->check(100000, 'goodsender@gooddomain.tld', 'rcpt1@gooddomain.tld', 'rcpt2@gooddomain.tld', 'rcpt3@gooddomain.tld');
} 'check mail address';
cmp_ok( $r->is_all_success, 'eq', 1, 'must be successfull');
cmp_ok( scalar($r->successfull_rcpts), 'eq', 3, '3 rcpts must be successfull');

lives_ok {
  $r = $v->check(100000, 'badsender@gooddomain.tld', 'rcpt1@gooddomain.tld', 'rcpt2@gooddomain.tld', 'rcpt3@gooddomain.tld');
} 'check mail address';
cmp_ok( $r->is_all_success, 'eq', 0, 'must be NOT successfull');
cmp_ok( scalar($r->successfull_rcpts), 'eq', 0, 'no rcpt should be successfull');
cmp_ok( scalar($r->perm_error_rcpts), 'eq', 3, '3 rcpts should be permanent error');

lives_ok {
  $r = $v->check(100000, 'goodsender@gooddomain.tld', 'badrcpt1@gooddomain.tld', 'rcpt2@gooddomain.tld', 'rcpt3@gooddomain.tld');
} 'check mail address';
cmp_ok( $r->is_all_success, 'eq', 0, 'must be NOT successfull');
cmp_ok( scalar($r->successfull_rcpts), 'eq', 2, '2 rcpts must be successfull');
cmp_ok( scalar($r->perm_error_rcpts), 'eq', 1, '1 rcpts must be permanent error');

$s->stop_ok;
