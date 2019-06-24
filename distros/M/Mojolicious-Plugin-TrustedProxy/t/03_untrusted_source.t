use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use lib::relative 'lib';

our $TEST = __FILE__;
$TEST =~ s/(?>t\/)?(.+)\.t/$1/;

# Test suite variables
my $t   = Test::Mojo->new('TestApp', {trustedproxy => {
  trusted_sources => ['1.1.1.1'],
}});
my $tid = 0;
my $tc  = 0;

# IP baseline
$tid++;
$tc += 3;
$t->get_ok('/ip')
  ->status_is(200)->content_is('127.0.0.1', sprintf(
    '[%s.%d] Assert baseline that tx->remote_address == 127.0.0.1',
    $TEST, $tid)
  );

# Scheme baseline
$tid++;
$tc += 3;
$t->get_ok('/scheme')
  ->status_is(200)->content_is('http', sprintf(
    '[%s.%d] Assert baseline that req->is_secure == false',
    $TEST, $tid)
  );

# Header X-Real-IP ignored
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'X-Real-IP' => '1.1.1.1'})
  ->status_is(200)->content_is('127.0.0.1', sprintf(
    '[%s.%d] Assert from header X-Real-IP => 1.1.1.1 that tx->remote_address == 127.0.0.1 (unchanged)',
    $TEST, $tid)
  );

# Header X-SSL ignored
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'X-SSL' => 1})
  ->status_is(200)->content_is('http', sprintf(
    '[%s.%d] Assert from header X-SSL => 1 that req->is_secure == false (unchanged)',
    $TEST, $tid)
  );

done_testing($tc);
