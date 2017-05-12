package Net::OpenVPN::DDNS;
use warnings;
use strict;
#
#
###############################################################################
# init libraries

use base qw( Class::Attrib Net::DHCP::DDNS );

use Net::OpenVPN::DDNS::Env;
use Net::OpenVPN::DDNS::Lease;
use Net::OpenVPN::DDNS::Local;
use Net::IP;

our $VERSION = 0.1;


###############################################################################
# define attributes and defaults

our %Attrib = (
		peer_name	=> undef,

		own_ipv4_addr	=> undef,
		own_ipv6_addr	=> undef,
		own_peer_addr	=> undef,

		its_ipv4_addr	=> undef,
		its_ipv6_addr	=> undef,
		its_peer_addr	=> undef,

		script_type	=> undef,
		dynamic_ccd	=> undef,

		ddnsdomainname	=> undef,
		peer_full_name	=> undef,

		iscdhcpdleases	=> undef,
		localclientdir	=> undef,

		dhcid_rrtype	=> 'rfc4701',
		foreign_fqdn	=> 'ignore'

);


###############################################################################
# call-in functions, only these should appear outside this module

sub configure {
	my ( $ctx, $cfg ) = @_;

	foreach my $key ( keys %$cfg ) {
		eval { $ctx->$key( $cfg->{$key} ) };
		warn $@ if $@;
	}

	return 1;
}


sub scriptrun {
	my $ctx = shift;

	Net::OpenVPN::DDNS::Env::internalize( $ctx )
		or die "Could not import OpenVPN environment.\n";

	my $mode = $ctx->script_type
		or die "Could not determine OpenVPN script type.\n";

	if ( $mode eq 'client-connect' ) {
		$ctx->initialize;
		my $rc = $ctx->run_add;
		return $rc;
	}

	if ( $mode eq 'client-disconnect' ) {
		$ctx->initialize;
		my $rc = $ctx->run_rem;
		return $rc;
	}

	die "Unknown script mode $mode.\n";

}


###############################################################################
# reverse domain helpers - move to Lookup?

sub revdomain($) {		# arg: ip address
	my $t = new Net::IP( shift ) or return undef;
	return $t->reverse_ip;
}

sub revlookup($) {		# arg: reverse domain name
	my $arg = shift;
	
	my $reply = Net::DHCP::DDNS::Lookup->send( $arg )
		or return;
				
	foreach my $rr ( $reply->answer ) {
		next unless $rr->type eq 'PTR';
		return $rr->ptrdname;
	}

	return undef;
}


###############################################################################
# common action handler code

sub initialize {
	my $ctx = shift;

	$ctx->getattributes;

#	$ctx->ddnsdomainname( $ctx->get_ddnsdomainname )
#		or return undef;

	$ctx->peer_full_name( $ctx->get_peer_full_name )
		or return undef;

	$ctx->dhcid( $ctx->get_dhcid );

	return $ctx;
}

sub getattributes {
	my $ctx = shift;
	my $num = 0;

	my $d = revdomain( $ctx->own_ipv4_addr || $ctx->own_ipv6_addr )
		or return undef;

	my $r = Net::DHCP::DDNS::Lookup->send( $d, 'TXT' )
		or return undef;

	foreach my $rr ( $r->answer ) {
		next unless $rr->type eq 'TXT';
		my $t = $rr->txtdata;
		my ( $k, $v ) = Net::DHCP::DDNS::Lookup->parseattribute( $t )
			or next;
		$ctx->$k( $v );
		$num++;
	}

	return $num;
}


###############################################################################
# client-connect action handler

sub run_add {
	my $ctx = shift;
	my ( $fqdn, @addrs );

	unless ( $fqdn = $ctx->peer_full_name ) {
		die "Could not determine fully qualified peer name!\n";
	}

	if ( my $ipv4 = $ctx->its_ipv4_addr ) {
		push @addrs, $ipv4;
	}

	if ( my $ipv6 = $ctx->its_ipv6_addr ) {
		push @addrs, $ipv6;
	}

	unless ( scalar( @addrs ) ) {
		die "Could not determine addresess to add!\n";
	}

	if ( $ctx->should_update_forward ) {
		unless ( $ctx->add( $fqdn, @addrs ) ) {
			die "Failed to update $fqdn, aborting!\n";
		}
	}

	foreach my $addr ( @addrs ) {
		my $d = revdomain( $addr );
		$ctx->add( $d, $fqdn ) if $d;
	}

	if ( $ctx->its_peer_addr ) {
		my $d = revdomain( $ctx->its_peer_addr );
		my $n = revlookup( $ctx->own_peer_addr );
		$ctx->add( $d, $n ) if ( $d and $n );
	}

	return 1;
}


###############################################################################
# client-disconnect action handler

sub run_rem {
	my $ctx = shift;
	my $fqdn;

	unless ( $fqdn = $ctx->peer_full_name ) {
		die "Could not determine fully qualified peer name!\n";
	}

	if ( $ctx->its_ipv4_addr ) {
		my $d = revdomain( $ctx->its_ipv4_addr );
		$ctx->rem( $d, $fqdn ) if $d;
	}

	if ( $ctx->its_ipv6_addr ) {
		my $d = revdomain( $ctx->its_ipv6_addr );
		$ctx->rem( $d, $fqdn ) if $d;
	}

	if ( $ctx->its_peer_addr ) {
		my $d = revdomain( $ctx->its_peer_addr );
		my $n = revlookup( $ctx->own_peer_addr );
		$ctx->rem( $d, $n ) if ( $d and $n );
	}

	if ( $ctx->should_update_forward ) {
		$ctx->rem( $fqdn, $ctx->its_ipv4_addr, $ctx->its_ipv6_addr );
	}

	return 1;
}


###############################################################################
# detail generators

sub get_clientids {
	my $ctx = shift;
	my %rv;

	my $name = $ctx->peer_name;

	if ( my $file = $ctx->iscdhcpdleases ) {

		my $obj = Net::OpenVPN::DDNS::Lease->get(
				file => $file,
				name => $name );

		if ( $obj ) {
			foreach my $type ( keys $obj->clientids ) {
				$rv{$type} = $obj->clientids->{$type};
			};
		}

	}

	if ( my $path = $ctx->localclientdir ) {

		my $obj = Net::OpenVPN::DDNS::Local->get(
				path => $path,
				name => $name );

		if ( $obj ) {
			foreach my $type ( keys $obj->clientids ) {
				$rv{$type} = $obj->clientids->{$type};
			};
		}

	}

	unless ( $rv{duid} or $rv{dcid} or $rv{hwid} ) {
		# no identifier was found, manufacture a legal one
		# dhcp-client-identifier, type 0 (arbitrary string)
		my $t = chr( 0 ) . $ctx->peer_name;
		$rv{dcid} = $t;
	}

	return %rv;
}

sub get_dhcid {
	my $ctx = shift;

	my %args = $ctx->get_clientids;

	$args{fqdn}  = $ctx->peer_full_name;
	$args{style} = $ctx->dhcid_rrtype;

	return Net::DHCP::DDNS::DHCID->new ( %args );
}

sub get_peer_full_name {
	my $ctx = shift;

	my $t = $ctx->peer_name; # FIXME or die
	my $d = $ctx->ddnsdomainname;

	if ( $t =~ /\./ ) {

		my $flag = lc( $ctx->foreign_fqdn );

		if ( $flag eq 'allow' ) {
			return $t;
		}

		if ( $flag eq 'deny' ) {

			my $soa_a = Net::DHCP::DDNS::Lookup->find_soa( $t );
			my $soa_b = Net::DHcP::DDNS::Lookup->find_soa( $d );

			unless ( $soa_a->name eq $soa_b->name ) {
				# FIXME set error message
				return undef;
			}

		}

	}

	$t =~ s/\..*//;

	return join( '.', $t, $d );
}

sub get_ddnsdomainname {
	my $ctx = shift;

	my $a = $ctx->own_ipv4_addr || $ctx->own_ipv6_addr
		or return undef;

	my $d = revdomain( $a )
		or return undef;

	my ( $t ) = Net::DHCP::DDNS::Lookup->getattrbyname(
		$d, 'ddnsdomainname' )
		or return undef;

	return $t;
}

sub should_update_forward {
	my $ctx = shift;

	my $soa_a = Net::DHCP::DDNS::Lookup->find_soa( $ctx->peer_full_name )
		or return undef;

	my $soa_b = Net::DHCP::DDNS::Lookup->find_soa( $ctx->ddnsdomainname )
		or return undef;

	return $soa_a->name eq $soa_b->name;
}


###############################################################################
1;
