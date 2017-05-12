package Net::OpenVPN::DDNS::Env;
use warnings;
use strict;
#
###############################################################################
###############################################################################
#
# 12-FEB-2014: Kevin Cody-Little <kcody@cpan.org>
# 	Initial version.
#
###############################################################################
# Access %ENV and store key values within the object.
#
# This is actually part of Net::OpenVPN::DDNS, but is kept here
# for clarity; this is its only data feed from the openvpn process.
#

sub internalize {
	my $ctx = shift;

	unless ( $ctx->peer_name( $ENV{common_name} ) ) {
		return 0;
	}

	unless ( $ctx->script_type( $ENV{script_type} ) ) {
		return 0;
	}

	$ctx->own_ipv4_addr( $ENV{ifconfig_local} );
	$ctx->own_ipv6_addr( $ENV{ifconfig_ipv6_local} );
	$ctx->own_peer_addr( $ENV{ifconfig_remote} );

	$ctx->its_ipv4_addr( $ENV{ifconfig_pool_remote_ip} );
	$ctx->its_ipv6_addr( $ENV{ifconfig_ipv6_pool_remote_ip6} );
	$ctx->its_peer_addr( $ENV{ifconfig_pool_local_ip} );

	$ctx->dynamic_ccd( shift @ARGV )
		if $ctx->script_type eq 'client-connect';

	return 1;
}


###############################################################################
## END OF FILE
###############################################################################
1;
