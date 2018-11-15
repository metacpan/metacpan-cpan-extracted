# $Id: 08-recurse.t 1719 2018-11-04 05:01:43Z willem $ -*-perl-*-

use strict;
use Test::More;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}

use Net::DNS;
use Net::DNS::Resolver::Recurse;

my @hints = new Net::DNS::Resolver()->_hints;

my @NOIP = qw(:: 0.0.0.0);


exit( plan skip_all => 'Online tests disabled.' ) if -e 't/online.disabled';
exit( plan skip_all => 'Online tests disabled.' ) unless -e 't/online.enabled';


eval {
	my $resolver = new Net::DNS::Resolver();
	exit plan skip_all => 'No nameservers' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;

	my @ns = grep $_->type eq 'NS', $reply->answer, $reply->authority;
	exit plan skip_all => 'Local nameserver broken' unless scalar @ns;

	1;
} || exit( plan skip_all => 'Non-responding local nameserver' );


eval {
	my $resolver = new Net::DNS::Resolver( nameservers => [@hints] );
	exit plan skip_all => 'No nameservers' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;
	my $from = $reply->from();

	my @ns = grep $_->type eq 'NS', $reply->answer;
	exit plan skip_all => "No NS RRs in response from $from" unless scalar @ns;

	exit plan skip_all => "Non-authoritative response from $from" unless $reply->header->aa;

	1;
} || exit( plan skip_all => 'Unable to reach global root nameservers' );


plan tests => 13;

NonFatalBegin();


{
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	ok( $res->isa('Net::DNS::Resolver::Recurse'), 'new() created object' );

	my $reply = $res->query_dorecursion( 'www.net-dns.org', 'A' );
	is( ref($reply), 'Net::DNS::Packet', 'query returned a packet' );
	skip( 'no response to query', 1 ) unless $reply;
	ok( scalar( $reply->answer ), 'answer section has RRs' );
}


{
	# test the callback
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	my $count = 0;

	$res->recursion_callback( sub { $count++ if ref(shift) } );

	$res->query_dorecursion( 'a.t.net-dns.org', 'A' );

	ok( $count >= 3, "Lookup took $count queries which is at least 3" );
}


{
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	my $count = 0;

	$res->recursion_callback( sub { $count++ if ref(shift) } );

	$res->query_dorecursion( '2a04:b900:0:0:8:0:0:60', 'PTR' );

	ok( $count >= 3, "Reverse lookup took $count queries" );
}


SKIP: {
	my $res	  = Net::DNS::Resolver::Recurse->new();
	is( scalar( $res->hints() ), 0, 'hints() initially empty' );
	$res->hints(@hints);
	is( scalar( $res->hints ), scalar(@hints), 'hints() set' );

	my $reply = $res->send( '.', 'NS' );
	is( ref($reply), 'Net::DNS::Packet', 'response received for priming query' );
	skip( 'no response to priming query', 3 ) unless $reply;
	my $from = $reply->from();

	ok( $reply->header->aa, "authoritative response from $from" );

	my @ns = grep $_->type eq 'NS', $reply->answer;
	ok( scalar(@ns), "NS RRs in response from $from" );

	my @ar = grep $_->can('address'), $reply->additional;
	ok( scalar(@ar), "address RRs in response from $from" );
}


{
	my $res = Net::DNS::Resolver::Recurse->new( nameserver => [@NOIP], srcport => -1 );

	ok( !$res->send( 'www.net-dns.org', 'A' ), 'fail if no reachable server' );
}


{
	Net::DNS::Resolver::Recurse->retry(0);
	my $res = Net::DNS::Resolver::Recurse->new();
	$res->hints(@NOIP);

	ok( !$res->send( 'www.net-dns.org', 'A' ), 'fail if no usable hint' );
}


NonFatalEnd();

exit;
