package Net::DHCP::DDNS::DHCID::rfc4701;
use warnings;
use strict;

our @ISA = qw( Net::DHCP::DDNS::DHCID );

use Digest::SHA qw( sha256 );


###############################################################################
# constructor helper

sub init {
	my $self = shift;

	$self->{rrtype} = 'DHCID';

	unless ( $self->{fqdn} ) {
		warn "DDNS bug: DHCID requires client FQDN.\n";
		return undef;
	}

	return 1;
}


###############################################################################
# detail accessors

sub identifier_type {	# rfc4701 3.3
	my $self = shift;

	# 0x0000 - 1 octet hwtype followed by hlen octets of chaddr
	if ( $self->id_type eq 'HWID' ) {
		return chr( 0x00 ) . chr( 0x00 );
	}

	# 0x0001 - data octets (type and id fields) from dhcp client identifier
	if ( $self->id_type eq 'DCID' ) {
		return chr( 0x00 ) . chr( 0x01 );
	}

	# 0x0002 - duid or duid field from dhcp client identifier
	if ( $self->id_type eq 'DUID' ) {
		return chr( 0x00 ) . chr( 0x02 );
	}

	return undef;
}

sub digest_type {	# rfc4701 3.4
	my $self = shift;

	# 0x00 - reserved
	# 0x01 - SHA-256

	return chr( 0x01 );
}

sub digest {
	my $self = shift;

	if ( $self->digest_type eq chr( 0x01 ) ) {
		return sha256( $self->idvalue . $self->fqdn );
	}

	else {	
		my $t = printf "0x%x", ord( $self->digest_type );
		warn "DDNS error: unknown DHCID digest type '$t'\n";
		return undef;
	}

}

sub encode {
	my $self = shift

	return encode_base64( shift );
}


###############################################################################
# rfc4701 DHCID field, 35 bytes

sub form {		# rfc4701 3.5
	my $self = shift;

	my $buf = $self->identifier_type
		. $self->digest_type
		. $self->digest;

	my $t = new IO::File;
	$t->open( "> /tmp/dhcid.tmp" )
	and print $t $buf and $t->close;

	return $buf;
}


###############################################################################
1;
