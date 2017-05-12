use Test::More tests => 14;

use Socket;
use Socket6;
use Socket::Multicast6 qw/ :all /;

my @socket_options = (
	'AF_INET',
	'AF_INET6',
	'IPPROTO_IP',
	'IPPROTO_IPV6',

	'IP_MULTICAST_IF',
	'IP_MULTICAST_TTL',
	'IP_MULTICAST_LOOP',
	'IP_ADD_MEMBERSHIP',
	'IP_DROP_MEMBERSHIP',
	'IPV6_MULTICAST_IF',
	'IPV6_MULTICAST_HOPS',
	'IPV6_MULTICAST_LOOP',
	'IPV6_JOIN_GROUP',
	'IPV6_LEAVE_GROUP'
);


#
# We don't currently check for SSM/Protocol-Independent Multicast
#

foreach my $opt ( @socket_options ) {
	my $value = eval "$opt";
	
	ok( defined $value, "Value of $opt is defined" );
}

