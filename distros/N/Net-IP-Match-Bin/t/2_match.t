
use Test::More tests => 8;
use Net::IP::Match::Bin;

my $ipm = Net::IP::Match::Bin->new();

my ($res, $res1, $res2, $res3, $res4, $res5, $res6);
my %ent = ("222.222.222.0/25" => "Spam",
		"202.202.202.0/16" => "another spam");
my $rv = $ipm->add(\%ent);

$res1 = $ipm->match_ip("222.222.222.1");
$res2 = $ipm->match_ip("202.202.222.222");
$res3 = $ipm->match_ip("202.203.202.202");
ok(	defined($res1) && ($res1 eq "Spam")
	&& defined($res2) && ($res2 eq "another spam")
	&& !defined($res3) , "match 1");

$res = $ipm->match_ip("222.222.222.128");
ok(!defined($res), "match 2");

$ipm->add("10.1.0.0/17");
$res = $ipm->match_ip("10.1.0.1");
ok(defined($res) && ($res eq "10.1.0.0/17"), "match 3");

$res = $ipm->match_ip("10.1.128.1");
ok(!defined($res), "match 4");

# as of 0.14
$ipm->add([ "192.168.0.128", "192.168.0.129" ]);
$res1 = $ipm->match_ip("192.168.0.128/31");
$res2 = $ipm->match_ip("192.168.0.127");
$res3 = $ipm->match_ip("192.168.0.128");
$res4 = $ipm->match_ip("192.168.0.129");
$res5 = $ipm->match_ip("192.168.0.130");
$res6 = $ipm->match_ip("192.168.0.128/30");
ok(	defined($res1)
	&& !defined($res2)
	&& defined($res3)
	&& defined($res4)
	&& !defined($res5)
	&& !defined($res6), "match 5");


# function calls
$res = match_ip("172.16.5.1", "172.16.0.0/16", "192.168.1.0/24");
ok (defined($res) && ($res eq "172.16.0.0/16"), "match 6");

$res = match_ip("172.16.5.1", "172.16.5.1/32", "192.168.1.0/24");
ok (defined($res) && ($res eq "172.16.5.1/32"), "match 7");

$res = match_ip("192.16.5.1", "172.16.0.0/16", "192.168.1.0/24");
ok (!defined($res), "match 8");

