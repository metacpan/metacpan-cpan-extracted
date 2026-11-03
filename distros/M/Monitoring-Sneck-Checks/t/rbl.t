#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;

plan( skip_all => 'needs Net::IP' ) if !eval { require Net::IP; 1 };
require FakeDNS;
require Monitoring::Sneck::Checks;

my $rbl = sub {
	my (@args) = @_;
	return Monitoring::Sneck::Checks->run(
		check => 'rbl',
		args  => [ '-s', 'bl.example.net', '-s', 'dnsbl.example.com', @args ]
	);
};
%FakeDNS::ANSWERS = (
	'25.2.0.192.bl.example.net a'    => { answer => ['25.2.0.192.bl.example.net. 300 IN A 127.0.0.2'] },
	'25.2.0.192.dnsbl.example.com a' => undef,
	'mail.example.org a'             => { answer => ['mail.example.org. 300 IN A 192.0.2.26'] },
	'mail.example.org aaaa'          => { answer => ['mail.example.org. 300 IN AAAA 2001:db8::1'] },
);

my $return = $rbl->( '-H', '192.0.2.10' );
is( $return->{code},        0,                                                                   'not listed' );
is( $return->{stdout},      "RBL OK - 192.0.2.10 listed 0 times in 2 lookups | listed=0;;0;0\n", 'output' );
is( $FakeDNS::ASKED[-2][1], '10.2.0.192.bl.example.net',                                         'reversed IPv4' );

$return = $rbl->( '-H', '192.0.2.25' );
is( $return->{code}, 2, 'listed is CRITICAL' );
like(
	$return->{stdout},
	qr/listed 1 times in 2 lookups, 192.0.2.25 on bl.example.net \(127.0.0.2\), no answer for 192.0.2.25 on dnsbl.example.com/,
	'listed, and the lookup with no answer'
);
is( $rbl->( '-H', '192.0.2.25', '-w', '0', '-c', '1' )->{code}, 1, 'listed once is WARNING with -w 0 -c 1' );

$return = $rbl->( '-H', 'mail.example.org' );
is( $return->{code}, 0, 'hostname' );
like( $return->{stdout}, qr/\ARBL OK - 192.0.2.26, 2001:db8::1 listed 0 times in 4 lookups/, 'both addresses' );
ok(
	(
		grep { $_->[1] eq '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.bl.example.net' }
			@FakeDNS::ASKED
	),
	'reversed IPv6'
);
is( $rbl->( '-H', 'nothing.example.org' )->{code}, 3, 'host with no addresses is UNKNOWN' );

%FakeDNS::ANSWERS = ( '10.2.0.192.bl.example.net a' => undef, '10.2.0.192.dnsbl.example.com a' => undef );
is( $rbl->( '-H', '192.0.2.10' )->{code}, 3, 'no answers is UNKNOWN' );
is( Monitoring::Sneck::Checks->run( check => 'rbl', args => [ '-H', '192.0.2.10' ] )->{code}, 3, 'no --rbl' );

done_testing();
