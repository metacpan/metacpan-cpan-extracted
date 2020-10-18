use strict;

use Test::More;
use Nuvol::Test::ConnectorLive ':all';

my $service = 'Dropbox';

my $connector = build_test_connector $service;

test_basics $connector, $service;
test_drivelist $connector;

done_testing();
