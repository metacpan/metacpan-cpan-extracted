# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DNS-ZoneParse.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Net::DNS::ZoneParse', qw(:parser)) };

#########################

my $result = <<"RRS";
foo.example.com.		IN	CNAME	bar.example.com.
bar.example.com.		IN	A	10.0.0.1
RRS

#TODO make the generator realize domains in rdata?
my $ooresult = <<"ORRS";
\$ORIGIN	example.com
foo		IN	CNAME	bar.example.com.
bar		IN	A	10.0.0.1
ORRS

my $rrs = [
	Net::DNS::RR->new("foo.example.com. IN CNAME bar.example.com."),
	Net::DNS::RR->new("bar.example.com. IN A 10.0.0.1"),
];

is(writezone($rrs), $result, "Export using Function-Interface");

SKIP: {
	eval { require DNS::ZoneParse };
	skip "DNS::ZoneParse isn't installed", 1 if $@;
	my $dzpres = <<"DZPRR";
;
;  Database file unknown for example.com. zone.
;	Zone version: 
;


			IN  SOA    (
					; serial number
					; refresh
					; retry
					; expire
					; minimum TTL
				)
;
; Zone NS Records
;

bar.example.com	0	IN	A	10.0.0.1
foo.example.com	0	IN	CNAME	bar.example.com
DZPRR
	is(writezone($rrs, {
				generator => [ qw( DNSZoneParse ) ],
				origin => "example.com",
				ttl => 3600,
		       	}), $dzpres,
		"Generating file using DNS::ZoneParse");
};

my $zoneparse = Net::DNS::ZoneParse->new();
$zoneparse->extent("example.com", $rrs);
is($zoneparse->writezone("example.com"), $ooresult,
       	"Export using Object oriented Interface");
