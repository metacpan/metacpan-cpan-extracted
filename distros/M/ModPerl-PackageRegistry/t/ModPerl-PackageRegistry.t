#!perl

use strict;
use warnings;
use lib "t/tlib";
use Apache::Test;
use Apache::TestRequest qw(GET_BODY GET);
use Apache::TestUtil;
use TestCommon::LogDiff;

use constant NOT_FOUND => 404;
use constant SERVER_ERROR => 500;

BEGIN { plan tests => 19 };

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';

t_debug("connecting to $hostport");
  
my $received;

$received = GET_BODY "/test/package-registry/good/good.test-reg";
ok t_cmp($received, "good ok", "basic handler");

$received = GET_BODY "/test/package-registry/good/good.test-reg";
ok t_cmp($received, "good ok", "basic handler cached");

my $log = TestCommon::LogDiff->new('t/logs/error_log');

$received = GET "/test/package-registry/good/missing.test-reg"; 
ok t_cmp($received->code, NOT_FOUND, "missing handler");
ok t_cmp($log->diff, qr{Can't locate .+? in \@INC}, "missing handler log");

$received = GET "/test/package-registry/good/buggy.test-reg"; 
ok t_cmp($received->code, SERVER_ERROR, "buggy handler");
ok t_cmp($log->diff, qr{use "TestRegistry::pages::buggy" failed}, "buggy handler log");

$received = GET "/test/package-registry/good/nohandler.test-reg";
ok t_cmp($received->code, SERVER_ERROR, "no handler");
ok t_cmp($log->diff, qr{"TestRegistry::pages::nohandler" does not provide}, "no handler log");

$received = GET "/test/package-registry/unrelated/good.test-reg";
ok t_cmp($received->code, NOT_FOUND, "skip handler");

$received = GET "/test/package-registry/bad/good.test-reg";
ok t_cmp($received->code, SERVER_ERROR, "bad config");
ok t_cmp($log->diff, qr{PackageNamespace is not defined}, "bad config log");

$received = GET_BODY "/test/package-registry/indexed-methods";
ok t_cmp($received, "index ok", "index handler");

$received = GET_BODY "/test/package-registry/indexed-methods/sub";
ok t_cmp($received, "sub index ok", "sub index handler");

$received = GET_BODY "/test/package-registry/indexed-methods/index";
ok t_cmp($received, "index ok", "method handler");

$received = GET "/test/package-registry/indexed-methods/good";
ok t_cmp($received->code, SERVER_ERROR, "bad method handler");
ok t_cmp($log->diff, qr{Can't locate object method "content_type" via package "TestRegistry::pages::good"}, "bad method handler log");

$received = GET_BODY "/test/package-registry/default/good.default";
ok t_cmp($received, "good ok", "default handler");

$received = GET "/test/package-registry/default";
ok t_cmp($received->code, NOT_FOUND, "no index handler");
ok t_cmp($log->diff, qr{has no PackageIndex defined}, "no index handler log");
