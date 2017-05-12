
use Test::More tests => 2;
use Net::IP::Match::Bin;

my $ipm = Net::IP::Match::Bin->new();

my %ent = ("222.222.222.0/25" => "Spam",
		"202.202.202.0/16" => "another spam");
# add hash ref
my $rv = $ipm->add(\%ent);
# add CIDR
$ipm->add("10.1.0.0/17");
# add range
$ipm->add_range("100.200.40.23- 100.200.50.1");
# add single ip
$ipm->add("1.2.3.4");
my @a = sort $ipm->list;

# check last item
my $res = pop(@a);
ok(($res eq "222.222.222.0/25"), "list");

$res = $a[0];
ok($res eq "1.2.3.4/32", "single-ip as /32");

