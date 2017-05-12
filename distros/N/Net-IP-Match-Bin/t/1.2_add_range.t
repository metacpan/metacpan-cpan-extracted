
use Test::More tests => 2;
use Net::IP::Match::Bin;

my $ipm = Net::IP::Match::Bin->new();

my $rv = $ipm->add_range("10.200.1.0-10.201.5.5");
ok($rv, "add range1");

$rv = $ipm->add_range("10.200.3.0 - 10.200.5.1");
ok($rv, "add range2");
