#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

my %prerequisite = ( 'Net::DNS' => 1.38 );

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";	## no critic
	plan skip_all => "$package @revision not installed";
	exit;
}

plan tests => 11;

use Net::DNS::Multicast;


my $question = Net::DNS::Question->new( 'example.local.', 'AAAA' );
is( $question->qclass,		    'IN', 'default qclass' );
is( $question->unicast_response,    0,	  'MDNS unicast_response flag false' );
is( $question->unicast_response(1), 1,	  'set MDNS unicast_response flag' );
is( $question->qclass,		    'IN', 'unchanged qclass' );
is( $question->unicast_response,    1,	  'MDNS unicast_response flag true' );

my $rr = Net::DNS::RR->new('example.local AAAA ::1');
is( $rr->class,		 'IN', 'implicit RRclass' );
is( $rr->cache_flush,	 0,    'MDNS cache_flush flag false' );
is( $rr->class,		 'IN', 'unchanged RRclass' );
is( $rr->cache_flush(1), 1,    'set MDNS cache_flush flag' );
is( $rr->class,		 'IN', 'unchanged RRclass' );
is( $rr->cache_flush,	 1,    'MDNS cache_flush flag true' );

exit;

__END__

