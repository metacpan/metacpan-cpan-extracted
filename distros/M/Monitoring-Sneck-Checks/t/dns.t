#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use FakeDNS;
use Monitoring::Sneck::Checks;

my $dns = sub {
	my (@args) = @_;
	return Monitoring::Sneck::Checks->run( check => 'dns', args => [ '-s', '192.0.2.53', @args ] );
};
%FakeDNS::ANSWERS = (
	'www.example.org a' =>
		{ answer => [ 'www.example.org. 300 IN A 192.0.2.10', 'www.example.org. 300 IN A 192.0.2.11' ] },
	'example.org mx'      => { answer => ['example.org. 300 IN MX 10 Mail.Example.org.'], aa => 1 },
	'slow.example.org a'  => undef,
	'bad.example.org a'   => { rcode  => 'SERVFAIL' },
	'alias.example.org a' => { answer => ['alias.example.org. 300 IN CNAME www.example.org.'] },
	'www.example.org any' =>
		{ answer => [ 'www.example.org. 300 IN A 192.0.2.10', 'www.example.org. 300 IN AAAA 2001:db8::10' ] },
	'hinfo.example.org any' => { answer => ['hinfo.example.org. 3600 IN HINFO "RFC8482" ""'] },
);

my $return = $dns->( '-H', 'www.example.org' );
is( $return->{code}, 0, 'found' );
like(
	$return->{stdout},
	qr/\ADNS OK - www.example.org A 192.0.2.10, 192.0.2.11 in [0-9.]+ seconds from 192.0.2.53 \| time=[0-9.]+s;;;0\n\z/,
	'output'
);
is_deeply( $FakeDNS::ASKED[-1], [ ['192.0.2.53'], 'www.example.org', 'A' ], 'asked the server for it' );
is( $dns->( '-H', 'www.example.org', '-a', '192.0.2.11' )->{code}, 0, 'expected answer there' );
$return = $dns->( '-H', 'www.example.org', '-a', '192.0.2.12' );
is( $return->{code}, 2, 'expected answer missing' );
like( $return->{stdout}, qr/, missing 192.0.2.12 \|/, 'and says so' );
is( $dns->( '-H', 'example.org', '-q', 'mx', '-a', '10 mail.example.org', '-A' )->{code},
	0, 'MX, normalized, authoritative' );
like( $dns->( '-H', 'www.example.org', '-A' )->{stdout}, qr/DNS CRITICAL - .*, not authoritative/,
	'not authoritative' );
like( $dns->( '-H', 'nope.example.org' )->{stdout},
	qr/\ADNS CRITICAL - nope.example.org A got NXDOMAIN from/, 'NXDOMAIN' );
like( $dns->( '-H', 'bad.example.org' )->{stdout}, qr/got SERVFAIL/, 'SERVFAIL' );
like(
	$dns->( '-H', 'slow.example.org' )->{stdout},
	qr/\ADNS CRITICAL - no reply for slow.example.org A, query timed out\n\z/,
	'no reply'
);
like( $dns->( '-H', 'alias.example.org' )->{stdout}, qr/has no A records/, 'only a CNAME' );
is( $dns->( '-H', 'www.example.org', '-w', '@0:10' )->{code}, 1, 'slow' );
$FakeDNS::ANSWERS{'_dmarc.example.org txt'}
	= { answer => ['_dmarc.example.org. 300 IN TXT "v=DMARC1; p=reject; rua=mailto:dmarc@example.org"'] };
is( $dns->( '-H', '_dmarc.example.org', '-q', 'TXT', '-r', '^"v=DMARC1; p=(quarantine|reject)' )->{code}, 0,
	'--regex' );
like(
	$dns->( '-H', '_dmarc.example.org', '-q', 'TXT', '-r', 'p=none' )->{stdout},
	qr/, nothing matching \/p=none\/ \|/,
	'--regex not matching'
);
$return = $dns->( '-H', 'www.example.org', '-q', 'any', '-a', '192.0.2.10', '-a', '2001:db8::10' );
is( $return->{code}, 0, 'ANY takes every record' );
like(
	$return->{stdout},
	qr/\ADNS OK - www.example.org ANY A 192.0.2.10, AAAA 2001:db8::10 in /,
	'each said with its type'
);
like(
	$dns->( '-H', 'hinfo.example.org', '-q', 'ANY' )->{stdout},
	qr/\ADNS OK - hinfo.example.org ANY HINFO /,
	'a RFC 8482 answer is a answer'
);
is( $dns->( '-H', 'www.example.org', '-r', '(' )->{code},    3, 'bad --regex' );
is( $dns->( '-H', 'www.example.org', '-q', 'A;rm' )->{code}, 3, 'bad type' );
is( Monitoring::Sneck::Checks->run( check => 'dns' )->{code}, 3, 'no hostname' );

done_testing();
