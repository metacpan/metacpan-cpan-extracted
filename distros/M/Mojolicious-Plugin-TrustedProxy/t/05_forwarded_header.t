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

# Forwarded header remote address, also tests Forwarded override
$tid++;
$tc += 3;
$t->get_ok('/ip' => {'Forwarded' => 'for=1.1.1.1', 'X-Real-IP' => '2.2.2.2'})
  ->status_is(200)->content_is('1.1.1.1', sprintf(
    '[%s.%d] Assert from header Forward => for=1.1.1.1 that tx->remote_address == 1.1.1.1',
    $TEST, $tid)
  );

# Forwarded header proxy address
$tid++;
$tc += 3;
$t->get_ok('/proxyip' => {'Forwarded' => 'by=1.1.1.1'})
  ->status_is(200)->content_is('1.1.1.1', sprintf(
    '[%s.%d] Assert from header Forward => by=1.1.1.1 that tx->remote_proxy_address == 1.1.1.1',
    $TEST, $tid)
  );

# Forwarded header protocol, also tests Forwarded override
$tid++;
$tc += 3;
$t->get_ok('/scheme' => {'Forwarded' => 'proto=https', 'X-Forwarded-Proto' => 'http'})
  ->status_is(200)->content_is('https', sprintf(
    '[%s.%d] Assert from header Forwarded => proto=https that req->is_secure == true',
    $TEST, $tid)
  );

# Forwarded header host
$tid++;
$tc += 3;
$t->get_ok('/host' => {'Forwarded' => 'host=foo.bar.com'})
  ->status_is(200)->content_is('foo.bar.com', sprintf(
    '[%s.%d] Assert from header Forwarded => host=foo.bar.com that req->url->base->host == foo.bar.com',
    $TEST, $tid)
  );

# Forwarded with all values in one, plus IPv6 test
my $fwd_params = {
  for   => 'fc01:c0ff:ee::',
  by    => 'fc01:c0de::',
  proto => 'https',
  host  => 'foo.bar.com',
};

$tc += 2;
my $test = $t->get_ok('/all' => {
  'Forwarded' => sprintf(
    ' for=%s ; by=%s; proto=%s ;host=%s ',
    $fwd_params->{for},
    $fwd_params->{by},
    $fwd_params->{proto},
    $fwd_params->{host},
  ),
})->status_is(200);

# +- Test "for"
$tid++;
$tc++;
$test->json_is('/ua_ip' => $fwd_params->{for}, sprintf(
  '[%s.%d] from header Forwarded "for" that tx->remote_address == %s',
  $TEST, $tid, $fwd_params->{for})
);
# +- Test "by"
$tid++;
$tc++;
$test->json_is('/proxy_ip' => $fwd_params->{by}, sprintf(
  '[%s.%d] from header Forwarded "by" that tx->remote_proxy_address == %s',
  $TEST, $tid, $fwd_params->{by})
);
# +- Test "proto"
$tid++;
$tc++;
$test->json_is('/scheme' => $fwd_params->{proto}, sprintf(
  '[%s.%d] from header Forwarded "proto" that req->is_secure == %s',
  $TEST, $tid, $fwd_params->{proto})
);
# +- Test "host"
$tid++;
$tc++;
$test->json_is('/host' => $fwd_params->{host}, sprintf(
  '[%s.%d] from header Forwarded "host" that req->url->base->host == %s',
  $TEST, $tid, $fwd_params->{host})
);

done_testing($tc);
