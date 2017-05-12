use strict;
use warnings;

use ServiceNow::SOAP;
use Test::More;
use lib 't';
use TestUtil;

if (TestUtil::config) { plan tests => 2 } else { plan skip_all => "no config" };
my $sn = TestUtil::getSession();
my $outputs = $sn->execute("InstanceInfo");
ok (ref($outputs->{result}) eq "HASH", "result is HASH");
my @keys = keys %{$outputs->{result}};
ok (scalar(@keys) > 0, "num values is " . scalar(@keys));
foreach my $key (@keys) {
	my $value = $outputs->{result}->{$key};
	note "$key=$value\n";
}

1;
