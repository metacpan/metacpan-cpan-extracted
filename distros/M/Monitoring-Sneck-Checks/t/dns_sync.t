#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use FakeDNS;
use Monitoring::Sneck::Checks;

my $sync = sub { return Monitoring::Sneck::Checks->run( check => 'dns_sync', args => [@_] ) };
my $soa  = sub {
	my ($serial) = @_;
	return {
		aa     => 1,
		answer =>
			[ 'example.org. 300 IN SOA ns1.example.org. admin.example.org. ' . $serial . ' 3600 600 86400 300' ]
	};
};
%FakeDNS::ANSWERS = (
	'example.org ns' =>
		{ answer => [ 'example.org. 300 IN NS ns1.example.org.', 'example.org. 300 IN NS NS2.example.org.' ] },
	'ns1.example.org a'             => { answer => ['ns1.example.org. 300 IN A 192.0.2.53'] },
	'ns1.example.org aaaa'          => { answer => ['ns1.example.org. 300 IN AAAA 2001:db8::53'] },
	'ns2.example.org a'             => { answer => ['ns2.example.org. 300 IN A 192.0.2.54'] },
	'example.org soa @192.0.2.53'   => $soa->(2026110101),
	'example.org soa @2001:db8::53' => $soa->(2026110101),
	'example.org soa @192.0.2.54'   => $soa->(2026110101),
);

my $return = $sync->( '-z', 'example.org' );
is( $return->{code}, 0, 'in sync' );
is( $return->{stdout},
	"DNS_SYNC OK - example.org serial 2026110101, 3 answered, nameservers ns1.example.org, ns2.example.org\n",
	'output' );
is(
	$sync->( '-z', 'example.org.', '-4' )->{stdout},
	"DNS_SYNC OK - example.org serial 2026110101, 2 answered, nameservers ns1.example.org, ns2.example.org\n",
	'-4, and a trailing dot'
);
ok( !( grep { $_->[2] eq 'AAAA' } @FakeDNS::ASKED[ -3 .. -1 ] ), 'no AAAA asked for with -4' );

{
	local $FakeDNS::ANSWERS{'example.org soa @192.0.2.54'} = $soa->(2026110100);
	$return = $sync->( '-z', 'example.org' );
	is( $return->{code}, 1, 'behind is WARNING' );
	like(
		$return->{stdout},
		qr/, serials differ, 2026110101 on ns1.example.org \(192.0.2.53\), ns1.example.org \(2001:db8::53\); 2026110100 on ns2.example.org \(192.0.2.54\)\n\z/,
		'and which'
	);
	is( $sync->( '-z', 'example.org', '-c' )->{code}, 2, 'CRITICAL with -c' );
}
{
	local $FakeDNS::ANSWERS{'example.org soa @192.0.2.54'} = { answer => $soa->(2026110101)->{answer} };
	like( $sync->( '-z', 'example.org' )->{stdout},
		qr/\ADNS_SYNC CRITICAL - .*, ns2.example.org \(192.0.2.54\) is not authoritative\n\z/, 'lame' );
	local $FakeDNS::ANSWERS{'example.org soa @192.0.2.53'} = undef;
	like( $sync->( '-z', 'example.org' )->{stdout}, qr/ns1.example.org \(192.0.2.53\) did not answer/,
		'not answering' );
	local $FakeDNS::ANSWERS{'example.org soa @2001:db8::53'} = { rcode => 'REFUSED' };
	like( $sync->( '-z', 'example.org' )->{stdout}, qr/ns1.example.org \(2001:db8::53\) got REFUSED/, 'refused' );
}
{
	local $FakeDNS::ANSWERS{'ns2.example.org a'};
	delete( $FakeDNS::ANSWERS{'ns2.example.org a'} );
	like(
		$sync->( '-z', 'example.org' )->{stdout},
		qr/DNS_SYNC CRITICAL - .*, ns2.example.org has no address\n\z/,
		'no address'
	);
}
is(
	$sync->( '-z', 'example.org', '-n', '192.0.2.53', '-n', '192.0.2.54' )->{stdout},
	"DNS_SYNC OK - example.org serial 2026110101, 2 answered, nameservers 192.0.2.53, 192.0.2.54\n",
	'--nameserver'
);
like(
	$sync->( '-z', 'nope.example.org' )->{stdout},
	qr/\ADNS_SYNC CRITICAL - nope.example.org has no NS records/,
	'no NS'
);
is( $sync->( '-z', 'example.org', '-4', '-6' )->{code}, 3, '-4 and -6' );
is( $sync->()->{code},                                  3, 'no --zone' );

done_testing();
