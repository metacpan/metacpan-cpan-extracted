# $Id: 01-resolver-opt.t 1444 2016-01-05 10:01:10Z willem $    -*-perl-*-


use strict;
use Test::More tests => 37;

use File::Spec;
use Net::DNS;


# .txt because this test will run under windows, unlike the other file
# configuration tests.
my $test_file = File::Spec->catfile( 't', 'custom.txt' );		# redefines default config

my $object = new Net::DNS::Resolver( config_file => $test_file );
ok( $object->isa('Net::DNS::Resolver'), 'new() created object' );


my $no_file = File::Spec->catfile( 't', 'nonexist.txt' );
eval { new Net::DNS::Resolver( config_file => $no_file ); };		# presumed not to exist
my $exception = $1 if $@ =~ /^(.+)\n/;
ok( $exception ||= '', "new(): non-existent file\t[$exception]" );


my $res = new Net::DNS::Resolver( config_file => $test_file );

my @servers = $res->nameservers;
is( $servers[0], '10.0.1.42', 'nameserver list correct' );
is( $servers[1], '10.0.2.42', 'nameserver list correct' );

my @search = $res->searchlist;
is( $search[0], 'alt.net-dns.org', 'searchlist correct' );
is( $search[1], 'ext.net-dns.org', 'searchlist correct' );

is( $res->domain, 'alt.net-dns.org', 'domain correct' );


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
	answerfrom  => 'set',
	answersize  => 'set',
	);

while ( my ( $key, $value ) = each %bad_input ) {
	my $res = Net::DNS::Resolver->new( $key => $value );
	isnt( $res->{$key}, 'set', "$key is not set" );
}


exit;

