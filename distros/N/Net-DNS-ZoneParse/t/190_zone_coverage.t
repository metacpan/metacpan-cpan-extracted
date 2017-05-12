use Test::More tests => 11;
use Test::Deep;

my $module;
BEGIN { $module = 'Net::DNS::ZoneParse::Zone'};
BEGIN { use_ok($module) };
BEGIN { use_ok("Net::DNS::ZoneParse") };

my $rrs0 = noclass(superhashof( {
		name => "foo.example.com",
		class => "IN",
		ttl => 3600,
		type => "CNAME",
		cname => "bar.example.com",
	}));
my $rrs1 = noclass(superhashof({
		name => "bar.example.com",
		class => "IN",
		ttl => 3600,
		type => "A",
		address => "10.0.0.1",
	}));
my $rrs2 = noclass(superhashof({
		name => "foobar.example.com",
		class => "IN",
		type => "CNAME",
		cname => "foo.example.com",
	}));

eval { require Test::TestCoverage; };
my $coverage = $@?0:1;
Test::TestCoverage::test_coverage($module) if $coverage;

my $zone = Net::DNS::ZoneParse::Zone->new("example.com", {
		filename => "190_zone.db",
		path => "t",
	});
cmp_deeply($zone->rr, [ $rrs0, $rrs1 ], "New loads Zonefile");

$zone->add(Net::DNS::RR->new("foobar.example.com. IN CNAME foo.example.com."));
cmp_deeply($zone->rr, [ $rrs0, $rrs1, $rrs2 ], "adding RR");

$zone->{filename} .= "out";
$zone->save;
my $file;
open($file, "<", $zone->{filename}) or die "can't open $zone->{filename}: $!\n";
my $text = "";
$text .= $_ while(<$file>);
close($file);
my $zonetext = <<"TEXT";
\$ORIGIN	example.com
foo	3600	IN	CNAME	bar.example.com.
bar	3600	IN	A	10.0.0.1
foobar		IN	CNAME	foo.example.com.
TEXT

is($text, $zonetext, "Saving zone to file");

$zone->replace({ name => "bar.example.com" });
cmp_deeply($zone->rr, [ $rrs0, $rrs2 ], "Deleting RR by replace");


my $z2 = Net::DNS::ZoneParse->new({
		path => "t", prefix => "190_", suffix => ".db",
	})->zone("zone");
cmp_deeply($z2->rr, [ $rrs0, $rrs1 ],
	"Loading Zonefile via ZoneParse Interface");

$zone->delall;
if(-f $zone->{filename}) {
	fail("Deleting zonefile");
} else {
	pass("Deleting zonefile");
}

cmp_deeply($zone->rr, noclass([]), "Deleting all RRs");

SKIP: {
	skip "Test::TestCoverage isn't installed", 1 unless $coverage;
	Test::TestCoverage::ok_test_coverage($module);
}

SKIP: {
	eval { require Test::Pod::Coverage; };
	skip "Test::Pod::Coverage isn't installed", 1 if $@;
	Test::Pod::Coverage::pod_coverage_ok($module);
}
