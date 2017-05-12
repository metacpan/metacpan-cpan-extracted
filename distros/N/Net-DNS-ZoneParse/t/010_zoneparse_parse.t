# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DNS-ZoneParse.t'

#########################

use Test::More tests => 5;
use Test::Deep;
BEGIN { use_ok('Net::DNS::ZoneParse') };

#########################

my $result = [
	superhashof( {
		name => "example.com",
		class => "IN",
		type => "MX",
		ttl => 3600,
		preference => 1,
		exchange => "foo.example.com",
	}),
	superhashof( {
		name => "foo.example.com",
		class => "IN",
		type => "CNAME",
		cname => "bar.example.com",
	}),
	superhashof( {
		name => "bar.example.com",
		type => "A",
		address => "10.0.0.1",
	}),
	superhashof( {
		name => "example.com",
		class => "IN",
		type => "MX",
		ttl => 3500,
		preference => 10,
		exchange => "bar.example.com",
	}),
];

my $pos = tell(DATA);

my @fres = @{$result}[1..$#{$result}];

SKIP: {
	eval { require Net::DNS::ZoneFile::Fast; };
	skip "Net::DNS::ZoneFile::Fast isn't installed", 1 if $@;

	<DATA>;
	cmp_deeply(Net::DNS::ZoneParse::parse({
			       	fh => \*DATA,
			       	parser => [ qw(NetDNSZoneFileFast) ],
			}),
		noclass(\@fres), "Parsing via Net::DNS::ZoneFile::Fast");
	$. = 0;
	seek(DATA, $pos, 0);
};

SKIP: {
	eval { require Net::DNS::Zone::Parser; };
	skip "Net::DNS::Zone::Parser isn't installed", 1 if $@;

	<DATA>;
	cmp_deeply(Net::DNS::ZoneParse::parse({
				fh => \*DATA,
				parser => [ qw(NetDNSZoneParser) ],
				parser_args => {
					NetDNSZoneParser => {
						CREATE_RR => 1,
					},
				},
			}),
		noclass(\@fres), "Parsing via Net::DNS::Zone::Parser");
	$. = 0;
	seek(DATA, $pos, 0);

};

SKIP: {
	eval { require DNS::ZoneParse; };
	skip "DNS::ZoneParse isn't installed", 1 if $@;

	<DATA>;
	my $res = Net::DNS::ZoneParse::parse({
			fh => \*DATA,
			parser => [ qw(DNSZoneParse) ],
			origin => "example.com",
		});
	cmp_deeply($res, noclass([ $fres[1], $fres[0], $fres[2]] ),
		"Parsing via DNS::ZoneParse");
	$. = 0;
	seek(DATA, $pos, 0);

};

my $zoneparse = Net::DNS::ZoneParse->new();
cmp_deeply($zoneparse->parse(\*DATA), noclass($result), "Parsing native");

__END__
example.com.	IN 3600 MX 1 foo.example.com.
foo.example.com. IN CNAME bar.example.com.
bar.example.com. A 10.0.0.1
example.com.	3500 IN MX 10 bar.example.com.
