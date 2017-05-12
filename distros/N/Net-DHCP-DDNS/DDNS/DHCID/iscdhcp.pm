package Net::DHCP::DDNS::DHCID::iscdhcp;
use warnings;
use strict;

our @ISA = qw( Net::DHCP::DDNS::DHCID );

use Digest::MD5 qw( md5 );


###############################################################################
# constructor helper

sub init {
	my $self = shift;

	$self->{rrtype} = 'TXT';

	return 1;
}


###############################################################################
# detail accessors

sub identifier_type {
	my $self = shift;

	# although we specify four nibbles (0x0000) perl will ignore
	# the upper insignificant byte, so it is re-prepended below.

	# 0x0000 - 1 octet hwtype followed by hlen octets of chaddr
	if ( $self->id_type eq 'HWID' ) {
		return chr( 0x00 );
	}

	# 0x0001 - data octets (type and id fields) from dhcp client identifier
	if ( $self->id_type eq 'DCID' ) {
		return chr( 0x31 );
		# isc erroneously uses 61 (decimal), should be 1
		# then correctly despite what common/dns.c says, sets
		# the first nibble to ( ( 61 >> 4 ) & 0xf ), then
		# erroneously sets the second to 61 % 15, should be % 16
		# giving a decimal result of 49, or 0x31 hex
	}

	# 0x0002 - duid or duid field from dhcp client identifier
	if ( $self->id_type eq 'DUID' ) {
		return chr( 0x02 );
	}

	return undef;
}

sub digest {
	my $self = shift;

	return md5( $self->idvalue );
}

sub encode {
	my ( $self, $raw ) = @_;
	my $rv = '';

	for ( my $i = 0; $i < length( $raw ); $i++ ) {
		my $byte = ord( substr( $raw, $i, 1 ) );
		my $nib1 = ( $byte >> 4 ) & 0xf;
		my $nib2 = $byte & 0xf;
		$rv .= sprintf "%x%x", $nib1, $nib2;
	}

	return $rv;
}


###############################################################################
# ISC dhcpd interim TXT DHCID field, 17 bytes

sub form {
	my $self = shift;

	my $buf = $self->identifier_type
		. $self->digest;

	my $t = new IO::File;
	$t->open( "> /tmp/dhcid-txt.tmp" )
	and print $t $buf and $t->close;

	return $buf;
}


###############################################################################
1;
