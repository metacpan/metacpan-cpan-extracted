# $Id: 04-packet-truncate.t 1449 2016-02-01 12:27:12Z willem $ -*-perl-*-

use strict;
use Test::More tests => 33;

use Net::DNS;
use Net::DNS::ZoneFile;

my $source = new Net::DNS::ZoneFile( \*DATA );

my @rr = $source->read;

{
	my $packet = new Net::DNS::Packet('query.example.');
	$packet->push( answer	  => @rr );
	$packet->push( authority  => @rr );
	$packet->push( additional => @rr );
	my $unlimited = length $packet->data;
	my %before    = map { ( $_, scalar $packet->$_ ) } qw(answer authority additional);
	my $truncated = length $packet->truncate($unlimited);
	ok( $truncated == $unlimited, "unconstrained packet length $unlimited" );

	foreach my $section (qw(answer authority additional)) {
		my $before = $before{$section};
		my $after  = scalar( $packet->$section );
		is( $after, $before, "$section section unchanged, $before RRs" );
	}
	ok( !$packet->header->tc, 'header->tc flag not set' );
}


{
	my $packet = new Net::DNS::Packet('query.example.');
	$packet->push( answer	  => @rr );
	$packet->push( authority  => @rr );
	$packet->push( additional => @rr );
	my $unlimited = length $packet->data;
	my %before    = map { ( $_, scalar $packet->$_ ) } qw(answer authority additional);
	my $truncated = length $packet->truncate;		# exercise default size
	ok( $truncated < $unlimited, "long packet was $unlimited, now $truncated" );

	foreach my $section (qw(answer authority additional)) {
		my $before = $before{$section};
		my $after  = scalar( $packet->$section );
		ok( $after < $before, "$section section was $before RRs, now $after" );
	}
	ok( $packet->header->tc, 'header->tc flag set' );
}


{
	my $packet = new Net::DNS::Packet('query.example.');
	$packet->push( answer	  => @rr );
	$packet->push( authority  => @rr );
	$packet->push( additional => @rr );

	my $tsig = eval { $packet->sign_tsig( 'tsig.example', 'ARDJZgtuTDzAWeSGYPAu9uJUkX0=' ) };

	my $unlimited = length $packet->data;
	my %before    = map { ( $_, scalar $packet->$_ ) } qw(answer authority additional);
	my $truncated = length $packet->data(512);		# explicit minimum size
	ok( $truncated < $unlimited, "signed packet was $unlimited, now $truncated" );

	foreach my $section (qw(answer authority additional)) {
		my $before = $before{$section};
		my $after  = scalar( $packet->$section );
		ok( $after < $before, "$section section was $before RRs, now $after" );
	}
	my $sigrr = $packet->sigrr;
	is( $sigrr, $tsig, 'TSIG still in additional section' );
	ok( $packet->header->tc, 'header->tc flag set' );
}


{
	my $packet = new Net::DNS::Packet('query.example.');
	my @auth = map Net::DNS::RR->new( type => 'NS', nsdname => $_->name ), @rr;
	$packet->unique_push( authority => @auth );
	$packet->push( additional => @rr );
	$packet->edns->size(2048);				# + all bells and whistles
	my $unlimited = length $packet->data;
	my %before    = map { ( $_, scalar $packet->$_ ) } qw(answer authority additional);
	my $truncated = length $packet->truncate;
	ok( $truncated < $unlimited, "referral packet was $unlimited, now $truncated" );

	foreach my $section (qw(answer authority)) {
		my $before = $before{$section};
		my $after  = scalar( $packet->$section );
		is( $after, $before, "$section section unchanged, $before RRs" );
	}

	foreach my $section (qw(additional)) {
		my $before = $before{$section};
		my $after  = scalar( $packet->$section );
		ok( $after <= $before, "$section section was $before RRs, now $after" );
	}
	ok( !$packet->header->tc, 'header->tc flag not set' );
}


{
	my $packet = new Net::DNS::Packet('query.example.');
	$packet->push( additional => @rr, @rr );		# two of everything
	my $unlimited = length $packet->data;
	my $truncated = length $packet->truncate( $unlimited >> 1 );
	ok( $truncated, "check RRsets in truncated additional section" );

	my %rrset;
	foreach my $rr ( grep $_->type eq 'A', $packet->additional ) {
		my $name = $rr->name;
		$rrset{"$name. A"}++;
	}

	foreach my $rr ( grep $_->type eq 'AAAA', $packet->additional ) {
		my $name = $rr->name;
		$rrset{"$name. AAAA"}++;
	}

	my $expect = 2;
	foreach my $key ( sort keys %rrset ) {
		is( $rrset{$key}, $expect, "$key	; $expect RRs" );
	}
}


exit;


__DATA__

a.example.	A	198.41.0.4
a.example.	AAAA	2001:503:ba3e::2:30
b.example.	A	192.228.79.201
b.example.	AAAA	2001:500:84::b
c.example.	A	192.33.4.12
c.example.	AAAA	2001:500:2::c
d.example.	A	199.7.91.13
d.example.	AAAA	2001:500:2d::d
e.example.	A	192.203.230.10
f.example.	A	192.5.5.241
f.example.	AAAA	2001:500:2f::f
g.example.	A	192.112.36.4
h.example.	A	128.63.2.53
h.example.	AAAA	2001:500:1::803f:235
i.example.	A	192.36.148.17
i.example.	AAAA	2001:7fe::53
j.example.	A	192.58.128.30
j.example.	AAAA	2001:503:c27::2:30
k.example.	A	193.0.14.129
k.example.	AAAA	2001:7fd::1
l.example.	A	199.7.83.42
l.example.	AAAA	2001:500:3::42
m.example.	A	202.12.27.33
m.example.	AAAA	2001:dc3::35

