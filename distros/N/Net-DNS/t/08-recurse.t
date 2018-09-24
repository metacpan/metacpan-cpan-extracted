# $Id: 08-recurse.t 1709 2018-09-07 08:03:09Z willem $ -*-perl-*-

use strict;
use Test::More;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}

use Net::DNS;
use Net::DNS::Resolver::Recurse;


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
	my $resolver = new Net::DNS::Resolver::Recurse();
	exit plan skip_all => "No nameservers" unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;
	my $from = $reply->from();

	my @ns = grep $_->type eq 'NS', $reply->answer;
	exit plan skip_all => "No NS RRs in response from $from" unless scalar @ns;

	exit plan skip_all => "Non-authoritative response from $from" unless $reply->header->aa;

	1;
} || exit( plan skip_all => 'Unable to reach global root nameservers' );


plan 'no_plan';

NonFatalBegin();


{
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	ok( $res->isa('Net::DNS::Resolver::Recurse'), 'new() created object' );

	my $packet = $res->query_dorecursion( 'www.net-dns.org', 'A' );
	ok( $packet, 'got a packet' );
	ok( scalar $packet->answer, 'answer section has RRs' ) if $packet;
}


{
	# test the callback
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	my $count = 0;

	$res->recursion_callback(
		sub {
			ok( shift->isa('Net::DNS::Packet'), 'callback argument is a packet' );
			$count++;
		} );

	$res->query_dorecursion( 'a.t.net-dns.org', 'A' );

	ok( $count >= 3, "Lookup took $count queries which is at least 3" );
}


{
	my $res = Net::DNS::Resolver::Recurse->new( debug => 0 );

	my $count = 0;

	$res->recursion_callback(
		sub {
			$count++;
		} );

	$res->query_dorecursion( '2a04:b900:0:0:8:0:0:60', 'PTR' );

	ok( $count >= 3, "Reverse lookup took $count queries" );
}


SKIP: {
	my @hints = new Net::DNS::Resolver::Recurse()->_hints;
	my $res	  = Net::DNS::Resolver::Recurse->new();
	is( scalar( $res->hints() ), 0, "hints() initially empty" );
	$res->hints(@hints);
	is( scalar( $res->hints ), scalar(@hints), "hints() set" );

	my $reply = $res->send( ".", "NS" );
	ok( $reply, 'got response to priming query' );
	skip( 'no response to priming query', 3 ) unless $reply;
	my $from = $reply->from();

	ok( $reply->header->aa, "authoritative response from $from" );

	my @ns = grep $_->type eq 'NS', $reply->answer;
	ok( scalar(@ns), "NS RRs in response from $from" );

	my @ar = grep $_->can('address'), $reply->additional;
	ok( scalar(@ar), "address RRs in response from $from" );
}


{
	my $res = Net::DNS::Resolver::Recurse->new();
	$res->retrans(0);
	$res->retry(0);
	$res->srcport(-1);

	ok( !$res->send( "www.net-dns.org", "A" ), 'fail if no reachable server' );
}


{
	Net::DNS::Resolver->retry(0);
	my $res = Net::DNS::Resolver::Recurse->new();
	$res->hints( '0.0.0.0', '::' );

	ok( !$res->send( "www.net-dns.org", "A" ), 'fail if no usable hint' );
}


NonFatalEnd();

exit;
