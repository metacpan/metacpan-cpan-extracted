package Net::DHCP::DDNS::API;
use warnings;
use strict;

use Class::Attrib 1.02;
use base 'Class::Attrib';

use Carp;
use Net::DNS;
use Net::IP	qw( &ip_is_ipv4 ip_is_ipv6 );

use Net::DHCP::DDNS::DHCID;
use Net::DHCP::DDNS::Update;


###############################################################################
# config accessors

our %Attrib = (

	# behavior controls
	no_purge_fwd			=>	0,
	no_purge_fwd_other		=>	0,
	strict_rfc4703			=>	0,

	# tsig keys
	ddns_key_root			=>	'/etc/ddns/keys',

	# opaque dhcp client identification
	dhcid				=>	'',

);


###############################################################################
# detect forward or reverse dns domain name

sub _is_forward($) {		# arg: dns domain name
	my $dname = shift;

	my $rv = 1;
	$rv = 0 if $dname =~ /\.ip6\.arpa\.$/;
	$rv = 0 if $dname =~ /\.in-addr\.arpa\.$/;

	return $rv;
}


###############################################################################
# turn raw values into resource records

sub _values_to_rrset($$@) {	# arg: is_fwd, @values
				# FIXME: research better validity checking
	my $is_fwd = shift;
	my $dname  = shift;
	my @rv;

	while ( my $value = shift ) {

		next unless $value;

		if ( ref( $value ) ) {

			unless ( $value->isa( 'Net::DNS::RR' ) ) {
				confess "Expecting string or Net::DNS::RR";
			}

			push @rv, $value;

		}

		if ( ip_is_ipv4( $value ) ) {
			push @rv, Net::DNS::RR->new( type	=> 'A',
						     name	=> $dname,
						     address	=> $value );
			next;
		}

		if ( ip_is_ipv6( $value ) ) {
			push @rv, Net::DNS::RR->new( type	=> 'AAAA',
						     name	=> $dname,
						     address	=> $value );
			next;
		}

		unless ( $is_fwd ) {
			push @rv, Net::DNS::RR->new( type	=> 'PTR',
						     name	=> $dname,
						     ptrdname	=> $value );
			next;
		}

		push @rv, Net::DNS::RR->new( type	=> 'CNAME',
					     name	=> $dname,
					     cname	=> $value );

	}

	return @rv;
}


###############################################################################
# operation methods

sub add {
	my $self = shift;
	my $dname = shift;

# FIXME: validity checking

	my $is_fwd = _is_forward( $dname );

	my @a = ( $self, $dname, _values_to_rrset( $is_fwd, $dname, @_ ) );

	return $is_fwd
		? Net::DHCP::DDNS::Update::add_forward( @a )
		: Net::DHCP::DDNS::Update::add_reverse( @a );
}

sub rem {
	my $self = shift;
	my $dname = shift;

# FIXME: validity checking

	my $is_fwd = _is_forward( $dname );

	my @a = ( $self, $dname, _values_to_rrset( $is_fwd, $dname, @_ ) );

	return _is_forward( $dname )
		? Net::DHCP::DDNS::Update::rem_forward( @a )
		: Net::DHCP::DDNS::Update::rem_reverse( @a );
}


###############################################################################
# turn Net::DHCP::DDNS::DHCID into a Net::DNS::RR::DHCID

sub dhcid_rr {
	my ( $self, $dname ) = @_;

	my $obj = $self->dhcid
		or return undef;

	my $txt = join( ' ', $dname, $obj->rrtype, $obj->value );

	return Net::DNS::RR->new( $txt );
}


###############################################################################
1;
