# $Id: 01-resolver-opt.t 1709 2018-09-07 08:03:09Z willem $    -*-perl-*-

use strict;
use Test::More tests => 30;

use Net::DNS::Resolver;

local $ENV{'RES_NAMESERVERS'};
local $ENV{'RES_SEARCHLIST'};
local $ENV{'LOCALDOMAIN'};
local $ENV{'RES_OPTIONS'};


#
# Check that we can set things in new()
#
my %test_config = (
	domain	       => 'net-dns.org',
	searchlist     => ['net-dns.org', 't.net-dns.org'],
	nameservers    => ['10.0.0.1', '10.0.0.2'],
	debug	       => 1,
	defnames       => 0,
	dnsrch	       => 0,
	recurse	       => 0,
	retrans	       => 6,
	retry	       => 5,
	persistent_tcp => 1,
	persistent_udp => 1,
	tcp_timeout    => 60,
	udp_timeout    => 60,
	usevc	       => 1,
	port	       => 54,
	srcport	       => 53,
	adflag	       => 1,
	cdflag	       => 0,
	dnssec	       => 0,
	);

foreach my $key ( sort keys %test_config ) {
	my $resolver = Net::DNS::Resolver->new( $key => $test_config{$key} );
	my @returned = $resolver->$key;
	my %returned = ( $key => scalar(@returned) > 1 ? [@returned] : shift(@returned) );
	is_deeply( $returned{$key}, $test_config{$key}, "$key is correct" );
}


#
# Check that new() is vetting things properly.
#
foreach my $test (qw(nameservers searchlist)) {
	foreach my $input ( {}, \1 ) {
		my $res = eval { Net::DNS::Resolver->new( $test => $input ); };
		ok( $@,	   'Invalid input caught' );
		ok( !$res, 'No resolver returned' );
	}
}


my %bad_input = (
	errorstring => 'set',
	replyfrom   => 'set',
	answerfrom  => 'set',		## historical
	);

while ( my ( $key, $value ) = each %bad_input ) {
	my $res = Net::DNS::Resolver->new( $key => $value );
	isnt( $res->$key, 'set', "$key is not set" );
}


exit;

