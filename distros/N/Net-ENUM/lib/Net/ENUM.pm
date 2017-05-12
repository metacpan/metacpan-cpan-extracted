#
# Net::ENUM - E.164 NUmber Mapping
#
# This module is Copyright (C) 2010, Detlef Pilzecker.
# All Rights Reserved.
# This module is free software. It may be used, redistributed and/or modified
# under the same terms as Perl itself.
#

package Net::ENUM;

use strict;
use Net::DNS qw( rrsort );

$Net::ENUM::VERSION = '0.3';


################################################################################
# Args: ( $class, %args )
#  $class: Net::ENUM
#  %args: see Net::DNS::Resolver->new(%args), this can overwrite Net::ENUM
#    default values! Example to use: udp_timeout => 5, ...
# Return: $self
################################################################################
sub new {
	my ( $class, $args, $vanity ) = @_;

	die '$args must be HASHREF' if $args && ref( $args ) ne 'HASH';

	if ( $vanity ) {
		die '$vanity must be HASHREF' if ref( $vanity ) ne 'HASH';
	}
	else {
		$vanity = {
			'abc'  => 2, 'def'  => 3, 'ghi'  => 4, 'jkl'  => 5,
			'mno'  => 6, 'pqrs' => 7, 'tuv'  => 8, 'wxyz' => 9,
		};
	}

	my $self = {
		'enum_error' => '',
		'res_args' => $args,
		'vanity' => $vanity,
	};

	bless( $self, $class );

	return $self;
}


################################################################################
# Args: ( $self, $number, $sortby, $media )
#  $number: Phone number in format: +123 456-789 or 9.8.7.6.5.4.3.2.1.e164.arpa
#  $sortby: sort based on the attribute (must be of type NAPTR), defaults to
#    'order' (= lowest to highest order, for same order lowest preference first)
#  $media: NAPTR media to return (sip, tel, email, ...), default: all
# Return:
#  if array is wanted: array with all sorted NAPTR entries in hashrefs
#    keys in the hashref: flags, ttl ,name, service, rdata, preference,
#                         rdlength, regexp, order, type, class, replacement
#  if string is wanted: string with contact of first NAPTR entry (after sorting)
#    the RegEx is already done!
#  <undef> on error
################################################################################
sub get_enum_address {
	my Net::ENUM $self = shift;
	my $e164 = $self->number_to_domain( shift ) or return;
	my $sortby = shift || 'order';
	my $media = shift;

	my $nameservers = $self->get_nameservers( $e164 ) or return;

	my $res = Net::DNS::Resolver->new(
		nameservers => $nameservers,
		recurse => 0,
		%{ $self->{'res_args'} }
	);

	my $NAPTR = $res->query( $e164, 'NAPTR' );

	if ( $NAPTR ) {
		my @rr_array = ( $NAPTR->answer );

		my @sorted = rrsort( 'NAPTR', $sortby, @rr_array );
		@sorted = grep { $_->{'service'} =~ /$media/ } @sorted if $media;

		if ( wantarray ) {
			$self->{'enum_error'} = '';
			return @sorted;
		}
		else {
			$sorted[0]->{'regexp'} =~ /^(.)(.+)\1(.+)\1/;
			my ( $pattern, $replace ) = ( $2, $3 );
			$e164 =~ s/$pattern/$replace/;

			$self->{'enum_error'} = '';
			return $e164;
		}
	}
	else {
		$self->{'enum_error'} = "'NAPTR' query failed: " . $res->errorstring . "\n";
		return;
	}
}


################################################################################
# Args: ( $self, $domain )
#  $domain: domain in format: 9.8.7.6.5.4.3.2.1.e164.arpa
# Return:
#  arrayref with nameservers, <undef> on error
################################################################################
sub get_nameservers {
	my Net::ENUM $self = shift;
	my $e164 = shift || return;

	my $res = Net::DNS::Resolver->new( %{ $self->{'res_args'} } );

	my $query = $res->query( $e164, 'NS' );

	if ( $query ) {
		$self->{'enum_error'} = '';
		return [ map { $_->nsdname } grep { $_->type eq 'NS' } $query->answer ];
	}
	else {
		$self->{'enum_error'} = "Nameservers query failed: " . $res->errorstring . "\n";
		return;
	}
}


################################################################################
# Args: ( $self, $number )
#  $number: Phone number in format: +123 456-789 or 9.8.7.6.5.4.3.2.1.e164.arpa
# Return:
#  9.8.7.6.5.4.3.2.1.e164.arpa, <undef> on error
################################################################################
sub number_to_domain {
	my Net::ENUM $self = shift;
	my $number = lc( shift );

	return $number if $number =~ /^(?:\d\.)+e164\.arpa$/;

	unless ( $number =~ /^\s*\+/ ) {
		$self->{'enum_error'} = "Phone number ($number) must begin with '+'.\n";
		return;
	}

	$self->translate_vanity( $number );

	$number =~ s/[^\d]//g;

	unless ( $number ) {
		$self->{'enum_error'} = "Phone number must contain numbers!\n";
		return;
	}

	$self->{'enum_error'} = '';
	return reverse( join( '.', split( //, $number ) ) ) . '.e164.arpa';
}


################################################################################
# Args: ( $self, $number )
#  $number: Phone number, can contain letters (vanity) they will be translatent
#           into numbers here
# Return:
#  translates the $number in place, but you can also use the returned 
################################################################################
sub translate_vanity {
	my Net::ENUM $self = $_[0];

	map { $_[1] =~ s/[$_]/$self->{'vanity'}{ $_ }/gi } keys %{ $self->{'vanity'} };

	return $_[1];
}

1;