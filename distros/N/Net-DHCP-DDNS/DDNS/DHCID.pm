package Net::DHCP::DDNS::DHCID;
use warnings;
use strict;

use Carp;
use MIME::Base64;

use Net::DHCP::DDNS::DHCID::rfc4701;
use Net::DHCP::DDNS::DHCID::iscdhcp;


sub new {
	my ( $class, %args ) = @_;

	$class = ref( $class ) if ref( $class );

	confess __PACKAGE__ . "::new($class) is asinine\n"
		unless $class->isa( __PACKAGE__ );

	$args{style} ||= 'rfc4701';

	my $t = $args{style};

	if ( $t eq 'rfc4701' ) {
		$class = 'Net::DHCP::DDNS::DHCID::rfc4701';
	}

	elsif ( $t eq 'iscdhcp' ) {
		$class = 'Net::DHCP::DDNS::DHCID::iscdhcp';
	}

	else {
		confess "unknown ddns update style '$t'";
	}

	bless my $self = {}, $class;

	if ( $t = $args{fqdn} ) {
		$self->import_fqdn( $t ) or return undef;
		$self->{fqdn} = $self->{idvalue};
	}

	if ( my $t = $args{duid} ) {
		$self->import_duid( $t ) or return undef;
	}

	elsif ( $t = $args{dcid} ) {
		$self->import_dcid( $t ) or return undef;
	}

	elsif ( $t = $args{hwid} ) {
		$self->import_hwid( $t ) or return undef;
	}

	unless ( scalar( keys %$self ) ) {
		warn "DDNS error: no basis to determine DHCID!\n";
		return undef;
	}

	return $self->init ? $self : undef;
}


###############################################################################
# import methods

sub import_duid {
	my ( $self, $duid ) = @_;

	$self->{id_type} = 'DUID';
	$self->{idvalue} = $duid;

	return $duid;
}

sub import_dcid {
	my ( $self, $dcid ) = @_;

	$self->{id_type} = 'DCID';
	$self->{idvalue} = $dcid;

	return $dcid;
}

sub import_hwid { # assumed ethernet
	my ( $self, $hwid ) = @_;
	my $rv;

	if ( $hwid =~ /:/ ) {

		$hwid =~ s/^['"]//;
		$hwid =~ s/['"]$//;
		chomp( $hwid );

		$rv = chr( 0x01 );

		grep {
			$rv .= chr( hex( $_ ) );
		} split /:/, $hwid;

	}

	elsif ( length( $hwid ) == 7 ) {
		$rv = $hwid;
	}

	else {
		warn "DDNS error: weird hwid '$hwid'";
		return undef;
	}

	$self->{id_type} = 'HWID';
	$self->{idvalue} = $rv;

}

sub import_fqdn {
	my ( $self, $fqdn ) = @_;

	$self->{id_type} = 'FQDN';
	$self->{idvalue} = lc( $fqdn );

}


###############################################################################
# retrieval methods

sub rrtype {
	my $self = shift;

	return $self->{rrtype} || 'DHCID';
}

sub value {
	my $self = shift;

	return $self->{value} if $self->{value};
	return $self->{value} = $self->encode( $self->binvalue );
}


###############################################################################
# abstract methods

sub form {
	confess "unexpected abstract invocation";
}

sub encode {
	confess "unexpected abstract invocation";
}


###############################################################################
# raw retrieval methods

sub fqdn {
	my $self = shift;

	return $self->{fqdn};
}

sub id_type {
	my $self = shift;

	return $self->{id_type};
}

sub idvalue {
	my $self = shift;

	return $self->{idvalue};
}

sub binvalue {
	my $self = shift;

	return $self->{binvalue} if $self->{binvalue};
	return $self->{binvalue} = $self->form;
}


###############################################################################
1;
