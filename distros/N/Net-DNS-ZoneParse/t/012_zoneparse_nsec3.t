
#########################

use Test::More tests => 2;
use Test::Deep;
BEGIN { use_ok('Net::DNS::ZoneParse') };

#########################

my $result = [
	superhashof( {
		name => 'example.com',
		class => 'IN',
		type => 'NSEC3PARAM',
		iterations => '1',
		salt => '65535',
		hashalgo => '1',
	}),
	superhashof( {
		name => '0123459678.bar.com',
		class => 'IN',
		type => 'NSEC3',
		hnxtname => 'ED9KM22A8TAMS5U0',
		iterations => '1',
		salt => '1234',
		hashalgo => '1',
	}),
	superhashof( {
		name => 'bar.com',
		class => 'IN',
		type => 'RRSIG',
		sig => 'qGgja+/trimmed/Kr=',
		sigexpiration => '20110720121900',
		siginception => '20110719111900',
		algorithm => '5',
	}),
];

my $pos = tell(DATA);

my @fres = @{$result}[1..$#{$result}];


# (not testing against Net::DNS::Zone::Parser - tests fail when v0.02 installed on my workstation)

# (no point testing against Net::DNS::ZoneFile::Fast - v1.15 gets NSEC3PARAM salt wrong)

# (no point testing against DNS::ZoneParse - v1.10 doesn't know about NSEC3 / NSEC3PARAM)


SKIP: {	# NSEC3, NSEC3PARAM require Net::DNS::SEC
	eval { require Net::DNS::SEC; };
	skip "Net::DNS::SEC isn't installed", 1 if $@;

	my $zoneparse = Net::DNS::ZoneParse->new();
	my $parsed = $zoneparse->parse(\*DATA);

	cmp_deeply($parsed, noclass($result), "Parsing NSEC3/NSEC3PARAM with native parser");
};


__END__
example.com.	IN	NSEC3PARAM	1 0 1 65535
0123459678.bar.com.	IN	NSEC3	1 1 1 1234 ED9KM22A8TAMS5U0 A RRSIG
bar.com.		IN	RRSIG	NSEC3PARAM 5 2 3600 20110720121900 20110719111900 16828 bar.com. qGgja+/trimmed/Kr=

