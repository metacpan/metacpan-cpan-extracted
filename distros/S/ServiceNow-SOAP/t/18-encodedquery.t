use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 2 } 
else { plan skip_all => "no config" };

my $today = today;
note "today=$today";

my $sn = TestUtil::getSession();
my $incident = $sn->table("incident");
my $filter = TestUtil::config->{incident_filter};
note "filter=$filter";
my @recs = $incident->getRecords($filter);
my $count = @recs;

ok ($count >= 50, "At least 50 records retrieved");
ok ($count < 1000, "Fewer than 1000 records retrieved");

1;
