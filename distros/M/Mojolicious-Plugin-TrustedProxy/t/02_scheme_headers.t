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
$t->get_ok('/scheme')
  ->status_is(200)->content_is('http', sprintf(
    '[%s.%d] Assert baseline that req->is_secure == false',
    $TEST, $tid)
  );

# Header: [default] X-SSL: 0
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'X-SSL' => 0})
  ->status_is(200)->content_is('http', sprintf(
    '[%s.%d] Assert from header X-SSL => 0 that req->is_secure == false',
    $TEST, $tid)
  );

# Header: [default] X-SSL: 1
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'X-SSL' => 1})
  ->status_is(200)->content_is('https', sprintf(
    '[%s.%d] Assert from header X-SSL => 1 that req->is_secure == true',
    $TEST, $tid)
  );

# Header: [default] X-Forwarded-Proto: http
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'X-Forwarded-Proto' => 'http'})
  ->status_is(200)->content_is('http', sprintf(
    '[%s.%d] Assert from header X-Forwarded-Proto => http that req->is_secure == false',
    $TEST, $tid)
  );

# Header: [default] X-Forwarded-Proto: https
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'X-Forwarded-Proto' => 'https'})
  ->status_is(200)->content_is('https', sprintf(
    '[%s.%d] Assert from header X-Forwarded-Proto => https that req->is_secure == true',
    $TEST, $tid)
  );

done_testing($tc);
