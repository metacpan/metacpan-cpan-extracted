use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use lib::relative 'lib';

our $TEST = __FILE__;
$TEST =~ s/(?>t\/)?(.+)\.t/$1/;

# Test suite variables
my $t   = Test::Mojo->new('TestApp');
my $tid = 0;
my $tc  = 0;

# Baseline
$tid++;
$tc += 3;
$t->get_ok('/ip')
  ->status_is(200)->content_is('127.0.0.1', sprintf(
    '[%s.%d] Assert baseline that tx->remote_address == 127.0.0.1',
    $TEST, $tid)
  );

# Header: [default] X-Real-IP
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Real-IP' => '1.1.1.1'})
  ->status_is(200)->content_is('1.1.1.1', sprintf(
    '[%s.%d] Assert from header X-Real-IP => 1.1.1.1 that tx->remote_address == 1.1.1.1',
    $TEST, $tid)
  );

# Header: [default] X-Forwarded-For (single)
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Forwarded-For' => '1.1.1.1'})
  ->status_is(200)->content_is('1.1.1.1', sprintf(
    '[%s.%d] Assert from header X-Forwarded-For => 1.1.1.1 that tx->remote_address == 1.1.1.1',
    $TEST, $tid)
  );

# Header: [default] X-Forwarded-For (multiple)
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Forwarded-For' => '1.1.1.1 , 2.2.2.2,3.3.3.3'})
  ->status_is(200)->content_is('1.1.1.1', sprintf(
    '[%s.%d] Assert from header X-Forwarded-For => "1.1.1.1 , 2.2.2.2,3.3.3.3" that tx->remote_address == 1.1.1.1',
    $TEST, $tid)
  );

# Check IPv6 support
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Forwarded-For' => 'fc01:c0ff:ee::'})
  ->status_is(200)->content_is('fc01:c0ff:ee::', sprintf(
    '[%s.%d] Assert from header X-Forwarded-For => fc01:c0ff:ee:: that tx->remote_address == fc01:c0ff:ee::',
    $TEST, $tid)
  );

# Check bad IP value
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Forwarded-For' => '123.456.789.000'})
  ->status_is(200)->content_is('127.0.0.1', sprintf(
    '[%s.%d] Assert from header X-Forwarded-For => 123.456.789.000 that tx->remote_address == 127.0.0.1',
    $TEST, $tid)
  );

# Check remote_proxy_address
$tid++;
$tc += 3;
$t->get_ok('/proxyip' => {'X-Real-IP' => '1.1.1.1'})
  ->status_is(200)->content_is('127.0.0.1', sprintf(
    '[%s.%d] Assert from header X-Real-IP => 1.1.1.1 that tx->remote_proxy_address == 127.0.0.1',
    $TEST, $tid)
  );

done_testing($tc);
