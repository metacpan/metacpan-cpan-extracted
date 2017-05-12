#===============================================================================
#
#         FILE:  SMS.pm
#
#  DESCRIPTION:  SMS message representation
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  14.08.2008 15:43:06 EEST
#===============================================================================

=head1 NAME

NetSDS::Message::SMS - short message according to ETSI GSM 03.40

=head1 SYNOPSIS

	use NetSDS::Message::SMS;

	...

	$msg = NetSDS::Message::SMS->new();
	$msg->udh(conv_hex_str('050102030405');
	$msg->ud('Hello there');

	$msg->coding(COD_7BIT);

	print "SM: " . $msg->message_body();

=head1 DESCRIPTION

This class provides API to SMS message data structure.

=cut

package NetSDS::Message::SMS;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::Message Exporter);

use version; our $VERSION = '0.021';

use NetSDS::Util::Convert;     # Data conversion routines
use NetSDS::Util::String;      # String processing routines
use NetSDS::Util::SMS;         # SMS related data processing
use NetSDS::Const::Message;    # Messaging related constants

our @EXPORT = qw(
  create_long_sm
);

#===============================================================================

=head1 CLASS API

=over

=item B<new()> - class constructor

Implements SMS constructor.

    my $object = NetSDS::Message::SMS->new();

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
		media   => 'sms',    # Bearer for messages
		headers => {
			udhi     => 0,           # UDH Indicator
			mclass   => undef,       # No message class by default
			coding   => COD_7BIT,    # Default GSM charset (ETSI GSM 03.38)
			mwi      => undef,       # Message Waiting Indicator (see DCS description)
			priority => 0,           # Non-priority messages
		},
		body => {
			udh => undef,            # User Data Headers
			ud  => undef,            # User Data
		},
		format => 'sms',             # Generic SMS data
		%params,
	);

	# Set SMS coding
	if ( defined $params{coding} ) {
		$this->coding( $params{coding} );
	}

	return $this;

} ## end sub new

#***********************************************************************

=item B<coding()> - set/get SMS coding

Paramters: new coding to set

Returns: message coding

	$msg->coding(COD_UCS2);

=cut 

#-----------------------------------------------------------------------

sub coding {

	my ( $this, $coding ) = @_;

	if ( defined $coding ) {

		# Check if coding is correct
		$coding += 0;
		if ( ( $coding < 0 ) or ( $coding > 2 ) ) {
			return $this->error("Cant set unknown data coding for SMS");
		}
		$this->header( 'coding', $coding );
	}

	return $this->header('coding');

}

#***********************************************************************

=item B<mclass()> - set/get message class

Paramters: new message class value

	$msg->mclass(0); # Send as Flash SMS

=cut 

#-----------------------------------------------------------------------

sub mclass {

	my ( $this, $mclass ) = @_;

	if ( defined $mclass ) {

		# Check if message class is correct
		$mclass += 0;
		if ( ( $mclass < 0 ) or ( $mclass > 3 ) ) {
			return $this->error("Cant set unknown message class for SMS");
		}
		$this->header( 'mclass', $mclass );
	}

	return $this->header('mclass');

}

#***********************************************************************

=item B<udh()> - set/get UDH

Paramters: UDH as binary string

Returns: UDH

	$msg->udh(conv_hex_str('050.02130405');

=cut 

#-----------------------------------------------------------------------

sub udh {

	my ( $this, $udh ) = @_;

	if ($udh) {

		$this->header( 'udhi', 1 );

		# Retrieve UDH length in bytes (1st
		my ($udhl) = unpack( "C*", bytes::substr( $udh, 0, 1 ) );

		# Check if UDH isn't more than maximum SMS size
		if ( $udhl > 139 ) {
			return $this->error("Cant set UDH more than 139 bytes");
		}

		# Check if UDHL is correct
		if ( ( $udhl + 1 ) != bytes::length($udh) ) {
			return $this->error("Incorrect UDHL in UDH");
		}

		$this->{body}->{udh} = str_decode($udh);
	}

	return $this->{body}->{udh};

} ## end sub udh

#***********************************************************************

=item B<ud()> - set/get user data

Paramters: user data as binary string

Returns: user data

=cut 

#-----------------------------------------------------------------------

sub ud {

	my ( $this, $ud ) = @_;

	if ( defined $ud ) {
		$this->{body}->{ud} = str_decode($ud);
	}

	return $this->{body}->{ud};

}

#***********************************************************************

=item B<esm_class()> - get esm_class from message

See 5.2.12 chapter of SMPP 3.4 specification for details.

	$esm_class = $msg->esm_class();

=cut 

#-----------------------------------------------------------------------

sub esm_class {

	my ($this) = @_;

	my $esm_class = 0b00000000;

	# Set UDHI to 1 if UDH exists
	if ( $this->udh() ) {
		$esm_class += 0b01000000;    # Set UDHI indicator
	}

	# Set DLR indicator if 'dlr' header presents
	if ( $this->header('dlr') ) {
		$esm_class += 0b00001000;    # Set DLR indicator
	}

	return $esm_class;
}

#***********************************************************************

=item B<dcs()> - get data coding scheme

Returns data coding schmeme in accordance with ETSI GSM 03.38

	$dcs = $msg->dcs();

=cut 

#-----------------------------------------------------------------------

sub dcs {

	my ($this) = @_;

	my $dcs = 0b00000000;

	# If have message class, bit 4 of DCS must be 1
	# Message class value set in 1 and 0 bits
	my $mclass = $this->header('mclass');
	if ( defined $mclass ) {
		$dcs += 0b00010000;     # Has message class
		$dcs += $mclass + 0;    # Message class value
	}

	# Add message coding (bits 2 and 3)
	$dcs += ( ( $this->header('coding') << 2 ) & 0b00001100 );

	return $dcs;
}

#***********************************************************************

=item B<message_body()> - return SMS message body

Returns: SMS body as byte string (UDH + UD)

	$msg_hex = conv_str_hex($msg->message_body);

=cut 

#-----------------------------------------------------------------------

sub message_body {

	my ($this) = @_;

	return $this->udh ? $this->udh . $this->ud : $this->ud;
}

#***********************************************************************

=item B<text($string, $coding)> - set SM data from text string

Paramters: string, SMS coding

	# Set SMS text
	$msg->text('Just some string', COD_7BIT);

This will set UDH to undef and UD to string in GSM 03.38.

=cut 

#-----------------------------------------------------------------------

sub text {

	my ( $self, $str, $coding ) = @_;
	$str = str_decode($str);

	$self->coding($coding);
	$self->{body}->{udh} = undef;    # only short text SMS

	# Convert UTF-8 string to proper encoding
	if ( $coding == COD_7BIT ) {
		$self->ud( str_recode( $str, 'UTF-8', 'GSM0338' ) );
	} elsif ( $coding == COD_UCS2 ) {
		$self->ud( str_recode( $str, 'UTF-8', 'UCS-2BE' ) );
	} else {
		return $self->error('Unknown encoding for text SM');
	}

	return $self->ud();

} ## end sub text


#***********************************************************************

=back

=head1 EXPORTED FUNCTIONS

=over

=item B<create_long_sm($text, $coding)> - concatenated SMS sequence

Paramters: text string (UTF-8), SMS coding

Returns: array of NetSDS::Message::SMS objects

	# Create 300 character string
	my $long_str = 'abc'x100;

	my @parts = create_long_sm($long_str, COD_7BIT);

=cut 

#-----------------------------------------------------------------------

sub create_long_sm {

	my ( $str, $coding ) = @_;

	# Parse string
	my @parts = NetSDS::Util::SMS::split_text( $str, $coding );

	# Create array of SMS objects
	my @res = ();
	foreach my $part (@parts) {
		my $msg = NetSDS::Message::SMS->new(
			coding => $coding,
		);
		$msg->udh( $part->{udh} );
		$msg->ud( $part->{ud} );
		push @res, $msg;
	}
	return @res;
}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory for examples.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

* ETSI GSM 03.38 - alphabets and language specific information

* ETSI GSM 03.40 - SMS realization on GSM networks

* SMPP Protocol Specification v3.4

=head1 TODO

* Implement RPI and message mode support in esm_class()

* Implement MWI support in dcs() method

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


