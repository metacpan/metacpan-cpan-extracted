use Test::More tests => 11;
use Test::Deep;

my $module;
BEGIN { $module = 'Net::DNS::ZoneParse'};
BEGIN { use_ok($module, qw(:parser)) };

my $rrs = [
		noclass(superhashof( {
			name => "foo.example.com",
			class => "IN",
			ttl => 3600,
			type => "CNAME",
			cname => "bar.example.com",
		})),
		noclass(superhashof({
			name => "bar.example.com",
			class => "IN",
			ttl => 3600,
			type => "A",
			address => "10.0.0.1",
		}))
];

my $rrs2 = [
		{
			name => "foobar.example.com",
			class => "IN",
			ttl => 3600,
			type => "A",
			address => "10.0.0.2",
		},
];

my $zone = <<"RES";
foo.example.com.	3600	IN	CNAME	bar.example.com.
bar.example.com.	3600	IN	A	10.0.0.1
RES

eval { require Test::TestCoverage; };
my $coverage = $@?0:1;
Test::TestCoverage::test_coverage($module) if $coverage;

my $zp = Net::DNS::ZoneParse::new();
my $res = $zp->parse(\*DATA);
cmp_deeply($res, $rrs, "Parsing Zonefile");
my $file = $zp->writezone($res);
is($file, $zone, "Dumping Zonefile");
$zp->extent("example.com", $rrs2);
$res = $zp->zone("example.com");
cmp_deeply($res->{rr}, [ @{$rrs}, @{$rrs2} ] , "Testing cache");
is(ref($zp->{"example.com"}), "Net::DNS::ZoneParse::Zone",
	"Access of zoneobject");
$zp->uncache("example.com");
is($zp->{"example.com"}, undef, "Removing zone from cache");

SKIP: {
	skip "Test::TestCoverage isn't installed", 1 unless $coverage;
	Test::TestCoverage::ok_test_coverage($module);
}

SKIP: {
	eval { require Test::Pod::Coverage; };
	skip "Test::Pod::Coverage isn't installed", 4 if $@;
	Test::Pod::Coverage::pod_coverage_ok( "Net::DNS::ZoneParse" );
	Test::Pod::Coverage::pod_coverage_ok(
		"Net::DNS::ZoneParse::Parser::Native" );
	Test::Pod::Coverage::pod_coverage_ok(
		"Net::DNS::ZoneParse::Parser::NetDNSZoneFileFast" );
	Test::Pod::Coverage::pod_coverage_ok(
		"Net::DNS::ZoneParse::Generator::Native" );

}

__END__
$ORIGIN example.com.
$TTL 3600

foo in cname bar.example.com.
bar in a 10.0.0.1
