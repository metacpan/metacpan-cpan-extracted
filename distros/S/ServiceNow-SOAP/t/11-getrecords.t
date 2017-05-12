use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 4 } else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();

my $cmn_location = $sn->table("cmn_location");
my @locs1 = $cmn_location->getRecords(__order_by => "name");
ok(@locs1 > 3, "At least 3 locations");
ok(@locs1 < 251, "Fewer than 250 locations returned");
my @locs2 = $cmn_location->getRecords(name => "Some nonsense location");
ok(@locs2 == 0, "Empty set returned");

SKIP: {
skip "aggregates disabled", 1 unless getProp("test_aggregates");
my $locationCount = $cmn_location->count();
ok($locationCount >= scalar(@locs1), "Location count = $locationCount");
}

1;
