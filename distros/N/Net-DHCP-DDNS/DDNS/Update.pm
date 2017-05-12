package Net::DHCP::DDNS::Update;
use warnings;
use strict;

use Carp;
use Net::DNS;
use Net::DHCP::DDNS::Lookup;
use Net::DHCP::DDNS::TSIG;
use Net::IP;


###############################################################################
# update request packet generator

sub _newpacket {
	my ( $api, $soa ) = @_;

	my $rv = new Net::DNS::Update $soa->name;

	my $tsig = Net::DHCP::DDNS::TSIG->get(
			domain => $soa->name,
			keydir => $api->ddns_key_root )
		or return $rv;

	$rv->sign_tsig( $tsig->name, $tsig->value );

	return $rv;
}


###############################################################################
# rfc4703 5.3 implementation - adding A/AAAA records

sub _rfc4703_add_forward($$$$$@) {
	my ( $api, $soa, $res, $dname, $dhcid, @rrset ) = @_;
	my ( $has_v4, $has_v6 ) = ( 0, 0 );
	my ( $num, $req, $rep );

	$num = grep {
		$_->type eq 'A'    and $has_v4 = 1;
		$_->type eq 'AAAA' and $has_v6 = 1;
		1;
	} @rrset;

	unless ( $has_v4 or $has_v6 ) {
		warn "DDNS: A or AAAA required to update $dname.\n";
		return undef;
	}

	if ( $api->strict_rfc4703 ) {
		if ( $dhcid->type ne 'DHCID' ) {
			warn "DDNS: DHCID RR required by RFC4703.\n";
			return undef;
		}
		if ( $has_v6 and $dhcid->identifiertype != 2 ) {
			warn "DDNS: DUID DHCID required with IPv6.\n";
			return undef;
		}
	}

	# rfc4703 5.3.1

retry_insert:
	$req = _newpacket( $api, $soa );
	$req->push( prereq => nxdomain( $dname ) );

	grep { $req->push( update => rr_add( $_->string ) ); } @rrset;

	$req->push( update => rr_add( $dhcid->string ) ) if $dhcid;

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 1 if $rep->header->rcode eq 'NOERROR';

	if ( $rep->header->rcode ne 'YXDOMAIN' ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	# rfc4703 5.3.2

	unless ( $dhcid ) {
		warn "DDNS error updating forward: no DHCID available\n";
		return undef;
	}

	$req = _newpacket( $api, $soa );
	$req->push( prereq => yxdomain( $dname ) );
	$req->push( prereq => yxrrset( $dhcid->string ) );

	if ( $has_v4 and $has_v6 ) {
		unless ( $api->no_purge_fwd_other ) {
			$req->push( update => rr_del( $dname . ' A' ) );
			$req->push( update => rr_del( $dname . ' AAAA' ) );
		}
	}

	if ( $has_v4 and not $has_v6 ) {
		unless ( $api->no_purge_fwd_other ) {
			$req->push( update => rr_del( $dname . ' AAAA' ) );
		}
		unless ( $api->no_purge_fwd ) {
			$req->push( update => rr_del( $dname . ' A' ) );
		}
	}

	if ( $has_v6 and not $has_v4 ) {
		unless ( $api->no_purge_fwd_other ) {
			$req->push( update => rr_del( $dname . ' A' ) );
		}
		unless ( $api->no_purge_fwd ) {
			$req->push( update => rr_del( $dname . ' AAAA' ) );
		}
	}

	grep { $req->push( update => rr_add( $_->string ) ) } @rrset;

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 1 if $rep->header->rcode eq 'NOERROR';
	return 0 if $rep->header->rcode eq 'NXRRSET';

	goto retry_insert if $rep->header->rcode eq 'NXDOMAIN';

	warn "DDNS error: ", $res->errorstring, "\n";

	return undef;
}


###############################################################################
# rfc4703 5.4 implementation - adding PTR records

sub _rfc4703_add_reverse($$$$$@) {
	my ( $api, $soa, $res, $dname, $dhcid, @rrset ) = @_;
	my ( $req, $rep, $dht );

	$req = _newpacket( $api, $soa );

	$dht = $dhcid->type if $dhcid;

	$req->push( update => rr_del( $dname . ' PTR' ) );
	$req->push( update => rr_del( $dname . ' ' . $dht ) ) if $dhcid;

	foreach my $rr ( @rrset ) {
		$req->push( update => rr_add( $rr->string ) );
	}

	$req->push( update => rr_add( $dhcid->string ) ) if $dhcid;

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 1 if $rep->header->rcode eq 'NOERROR';

	warn "DDNS error: ", $res->errorstring, "\n";
	return undef;
}


###############################################################################
# rfc4703 5.5 implementation - removing records

sub _rfc4703_rem_forward($$$$$@) {
	my ( $api, $soa, $res, $dname, $dhcid, @rrset ) = @_;
	my ( $req, $rep );
	my $dtype = $dhcid->type;
	my $dtext = $dhcid->rdatastr;

	$req = _newpacket( $api, $soa );

	$req->push( prereq => yxrrset( join( ' ', $dname, $dtype, $dtext ) ) );

	grep {
		$req->push( update => rr_del( $_->string ) );
	} @rrset;

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 0 if $rep->header->rcode eq 'NXRRSET';

	unless ( $rep->header->rcode eq 'NOERROR' ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	$req = _newpacket( $api, $soa );

	$req->push( prereq => yxrrset( join( ' ', $dname, $dtype, $dtext ) ) );
	$req->push( prereq => nxrrset( join( ' ', $dname, 'AAAA' ) ) );
	$req->push( prereq => nxrrset( join( ' ', $dname, 'A' ) ) );
	$req->push( update => rr_del( $dname ) );

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 1 if $rep->header->rcode eq 'NOERROR';

	warn "DDNS error: ", $res->errorstring, "\n";
	return undef;
}

sub _rfc4703_rem_reverse($$$$$$) {
	my ( $api, $soa, $res, $dname, $dhcid, $value ) = @_;
	my ( $req, $rep );

	my $pdname = $value->ptrdname;

	$req = _newpacket( $api, $soa );

	$req->push( prereq => yxrrset( join( ' ', $dname, 'PTR', $pdname ) ) );
	$req->push( update => rr_del( $dname ) );

	unless ( $rep = $res->send( $req ) ) {
		warn "DDNS error: ", $res->errorstring, "\n";
		return undef;
	}

	return 1 if $rep->header->rcode eq 'NOERROR';
	return 0 if $rep->header->rcode eq 'NXRRSET';

	warn "DDNS error: ", $res->errorstring, "\n";
	return undef;
}


###############################################################################
###############################################################################

###############################################################################
# common to all handlers

sub _init_handler($$) {
	my ( $api, $dname ) = @_;
	my ( $soa, $res, $dhcid );

	$soa = Net::DHCP::DDNS::Lookup->find_soa( $dname )
		or confess "could not find SOA for $dname";

	$res = Net::DNS::Resolver->new;
	$res->nameservers( $soa->mname );

	$dhcid = $api->dhcid_rr( $dname );

	return ( $soa, $res, $dhcid );
}


###############################################################################
# forward address handlers

sub add_forward {
	my ( $api, $dname, @rrset ) = @_;

	confess "called without dname" unless $dname;
	confess "called without value" unless @rrset;

	my ( $soa, $res, $dhcid ) = _init_handler( $api, $dname );

	return 1 if _rfc4703_add_forward(
				$api, $soa, $res, $dname, $dhcid, @rrset );

	# FAIL: domain is in use.
	return 0 if $api->strict_rfc4703;

	# try alternate schemes or force the issue ?

	# FAIL: domain is in use.
	return 0;
}

sub rem_forward {
	my ( $api, $dname, @rrset ) = @_;

	confess "called without dname" unless $dname;
	confess "called without value" unless @rrset;

	my ( $soa, $res, $dhcid ) = _init_handler( $api, $dname );

	return 1 if _rfc4703_rem_forward(
				$api, $soa, $res, $dname, $dhcid, @rrset );
	return 0;
}


###############################################################################
# reverse address handlers

sub add_reverse {
	my ( $api, $dname, $value ) = @_;

	confess "called without dname" unless $dname;
	confess "called without value" unless $value;

	my ( $soa, $res, $dhcid ) = _init_handler( $api, $dname );

	return 1 if _rfc4703_add_reverse(
				$api, $soa, $res, $dname, $dhcid, $value );
	return 0;
}

sub rem_reverse {
	my ( $api, $dname, $value ) = @_;

	confess "called without dname" unless $dname;
	confess "called without value" unless $value;

	my ( $soa, $res, $dhcid ) = _init_handler( $api, $dname );

	return 1 if _rfc4703_rem_reverse(
				$api, $soa, $res, $dname, $dhcid, $value );
	return 0;
}


###############################################################################
1;
