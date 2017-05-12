
use Test::More tests => 5;
use Net::IP::Match::Bin;

my $ipm = Net::IP::Match::Bin->new();

my $rv = $ipm->add("10.200.1.0/25");
ok($rv, "add scalar");

$rv = $ipm->add("10.100.0.0/16", "100.1.1.0/24");
ok($rv, "add multi");

$rv = $ipm->add(["10.100.0.0/16", "100.2.1.3/21"]);
ok($rv, "add list ref");

my %ent = ("222.222.222.0/16" => "Spam",
		"202.202.202.0/16" => "another spam");
$rv = $ipm->add(\%ent);
ok($rv, "add map");

$rv = $ipm->add();
ok(!$rv, "null arg");
