
use Test::More tests => 7;

use Net::IP::Match::Bin::Perl;

my $ipm = Net::IP::Match::Bin::Perl->new();

my %ent = ("222.222.222.0/25" => "Spam",
		"202.202.202.0/16" => "another spam");
my $rv = $ipm->add(\%ent);

my $res = $ipm->match_ip("222.222.222.1");
ok(defined($res) && ($res eq "Spam"), "match 1");

$res = $ipm->match_ip("222.222.222.128");
ok(!defined($res), "match 2");

$ipm->add("10.1.0.0/17");
$res = $ipm->match_ip("10.1.0.1");
ok(defined($res) && ($res eq "10.1.0.0/17"), "match 3 res=$res");

$res = $ipm->match_ip("10.1.128.1");
ok(!defined($res), "match 4");

# function calls
$res = match_ip("172.16.5.1", "172.16.0.0/16", "192.168.1.0/24");
ok (defined($res) && ($res eq "172.16.0.0/16"), "match 5 res=$res");

$res = match_ip("172.16.5.1", "172.16.5.1/32", "192.168.1.0/24");
ok (defined($res) && ($res eq "172.16.5.1/32"), "match 6 res=$res");

$res = match_ip("192.16.5.1", "172.16.0.0/16", "192.168.1.0/24");
$res = match_ip("192.16.5.1", "172.16.0.0/16", "192.168.1.0/24");
ok (!defined($res), "match 7");

