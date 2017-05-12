
use strict;
use Test::More tests => 6;
use Net::SenderBase;

SKIP: {
    skip "Network checks not in place", 6 unless -e '.do_net';
    my $query = Net::SenderBase::Query->new(Address => 'yahoo.com');

    ok($query->isa('Net::SenderBase::Query::DNS'), "check we got a dns query");
    my $results = $query->results;
    ok($results);
    ok($results->isa('Net::SenderBase::Results'), "check results is ok");
    ok($results->org_name =~ /yahoo/i, "check organisation name is OK");
    ok($results->version_number, "check we got a version back");
    ok($results->org_monthly_magnitude > 5.0, "check magnitude is at least 5");
}
