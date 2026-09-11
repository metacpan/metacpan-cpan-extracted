use v5.36;

use Test::More;

my $server = $ENV{PPLQUERY_TEST_URL};
diag(defined($server) && $server ne ''
    ? "PPLQUERY_TEST_URL is set: the integration test runs against the live OpenSearch server at $server"
    : 'PPLQUERY_TEST_URL is unset: the integration test runs against the loopback mock on http://127.0.0.1:9200');

use_ok('OpenSearch::PPLQuery');
use_ok('OpenSearch::PPLQuery::Connection');

done_testing();
