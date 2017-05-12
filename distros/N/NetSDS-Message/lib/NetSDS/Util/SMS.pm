#===============================================================================
#
#         FILE:  SMS.pm
#
#  DESCRIPTION:  Routines for SMS data.
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.08.2009 14:12:44 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::SMS - routines for SMS data processing

=head1 SYNOPSIS

	use NetSDS::Util::SMS;

	# Prepare 400 characters string
	my $long_line = "zuka"x100;

	# Split string to SMS parts
	my @sms = split_text($long_line, COD_7BIT);


=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=head1 DESCRIPTION

I hope you can understand what these routines doing.

Few basics:

	EMS
		$hex_sms = ie_melody($iMelody,'');
		$hex_sms = ie_bmp($BMP,'');

EMS Message is composed of several Information Elements
preceded by the User Data Header Length (1 byte).

So I used 'non-object' standard: different subroutines
producing different IE-Chunks. We can simply concantenate
these chunks in one message and precede it with UDHL (and
message-splitting elements if our EMS/IE stream don't fit
standard 140 bytes.

Resulting stream filled with plain HEX-coded octets.
Hexcodes are handy to use and can be easy converted to
binary or base64 formats.

There is no something-to-imelody converter. Look for it
in my ringtone.pm.

Pictures used as 1-bit Windows BMPs. I said 1-bit, ok?

=cut

package NetSDS::Util::SMS;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = '0.021';

use base qw(
  Exporter
  NetSDS::Class::Abstract
);

our @EXPORT_OK = qw(
  ems_essage

  ie_melody
  ie_icon16
  ie_icon32
  ie_picture
  ie_bmp

  smart_message
  smart_bmp
  smart_logo
  smart_card
  smart_cli
  smart_ringtone
  smart_clear
  smart_push_wap

  siemens_header
  siemens_message
  siemens

  split_text
);

use POSIX;
use NetSDS::Const;
use NetSDS::Const::Message;
use NetSDS::Util::Convert;
use NetSDS::Util::String;

# File Format Signatures => SEO Types:

my %SIGN = (
	'MT' => 'mid',
	'BM' => 'bmp'
);

########################################################################
# EMS
########################################################################
#***********************************************************************

=head1 EXPORTS

=over

=item B<ems_essage(...)>

$message_str = ems_essage ( ie_stream, text_data )

Produce a EMS message.
Sure that ie data + text can not exceed 139 bytes.

=cut

#-----------------------------------------------------------------------
sub ems_essage {
	my ( $ie_stream, $text, $encoding, $transport ) = @_;

	unless ( defined($text) ) {
		$text = '';
	}

	my $coding = COD_7BIT;
	if ( $text =~ m/[^\x00-\x7f]/ ) {
		$text = str_recode( $text, defined($encoding) ? $encoding : DEFAULT_ENCODING, to_enc => ENC_UNICODE );
		$coding = COD_UNICODE;
	}

	unless ( defined($transport) ) {
		$transport = TRANSPORT_ANY;
	}

	my $udhl = defined($ie_stream) ? bytes::length($ie_stream) : 0;
	if ($udhl) {
		# EMS Information Elements present...
		return [ { udh => pack( 'C', $udhl ) . $ie_stream, ud => $text, coding => $coding, transport => $transport } ];
	} else {
		# Plain text message. What a mess?..
		return [ { udh => '', ud => $text, coding => $coding, transport => $transport } ];
	}
} ## end sub ems_essage

#***********************************************************************

=item B<ie_melody(...)>

$ie_str = ie_melody ( melody )

Produce an iMelody Information Element.

WARNING: Melodies larger than 128 bytes will be CROPPED!

=cut

#-----------------------------------------------------------------------
sub ie_melody {
	my ( $raw, $text, $encoding, $transport ) = @_;

	my $l = length($raw);
	if ( $l > 128 ) {
		$raw = substr( $raw, 0, 128 );
		$l = 128;
	}

	return ems_essage( IEC_MELODY . pack( 'C*', ++$l, 0 ) . $raw, $text, $encoding, $transport );
}

#***********************************************************************

=item B<ie_icon32(...)>

=cut

#-----------------------------------------------------------------------
sub ie_icon32 {
	my ( $raw, $text, $encoding, $transport ) = @_;

	my $l = length $raw;
	if ( $l > 128 ) {
		$raw = substr( $raw, 0, 128 );
		$l = 128;
	}

	return ems_essage( IEC_ICON32 . pack( 'C*', ++$l, 0 ) . $raw, $text, $encoding, $transport );
}

#***********************************************************************

=item B<ie_icon16(...)>

=cut

#-----------------------------------------------------------------------
sub ie_icon16 {
	my ( $raw, $text, $encoding, $transport ) = @_;

	my $l = length $raw;
	if ( $l > 32 ) {
		$raw = substr( $raw, 0, 32 );
		$l = 32;
	}

	return ems_essage( IEC_ICON16 . pack( 'C*', ++$l, 0 ) . $raw, $text, $encoding, $transport );
}

#***********************************************************************

=item B<ie_picture(...)>

=cut

#-----------------------------------------------------------------------
sub ie_picture {
	my ( $raw, $width, $height, $text, $encoding, $transport ) = @_;

	if ( $width % 8 ) {
		return __PACKAGE__->error("Non-8x width");
	}

	my $squa = $width * $height / 8;
	if ( $squa > 128 ) {
		$height = int( 128 * 8 / $width );
		$squa   = $width * $height / 8;
	}

	my $l = length($raw);
	if ( $l > $squa ) {
		$raw = substr( $raw, 0, $squa );
		$l = $squa;
	}

	return ems_essage( IEC_PICTURE . pack( 'C*', $l + 3, 0, $width / 8, $height + 0 ) . $raw, $text, $encoding, $transport );
} ## end sub ie_picture

#***********************************************************************

=item B<ie_bmp(...)>

=cut

#-----------------------------------------------------------------------
sub ie_bmp {
	my ( $bmp, $text, $encoding, $transport ) = @_;

	if ( substr( $bmp, 0, 2 ) ne 'BM' ) {
		return __PACKAGE__->error("Not a BMP");
	}

	if ( unpack( 'L', substr( $bmp, 30, 4 ) ) ) {
		return __PACKAGE__->error("Compressed BMP");
	}

	unless ( unpack( 'S', substr( $bmp, 28, 2 ) ) == 1 ) {
		return __PACKAGE__->error("Need 1bpp monochrome BMP");
	}

	my $w   = unpack( 'L', substr( $bmp, 18, 4 ) );
	my $h   = unpack( 'L', substr( $bmp, 22, 4 ) );
	my $ofs = unpack( 'L', substr( $bmp, 10, 4 ) );

	my @bitmap = split( //, substr( $bmp, $ofs, length($bmp) ) );

	# Line Width in bytes
	my $line = int( $w / 8 );
	$line++ if ( $w % 8 );

	# Pad to 4x bytes
	my $padding = 0;
	$padding = 4 - $line % 4 if ( $line % 4 );

	my $raw = '';
	for ( my $y = 0 ; $y < $h ; $y++ ) {
		my $ll = '';
		for ( my $x = 0 ; $x < $line ; $x++ ) {
			$ll .= ~$bitmap[ $y * ( $line + $padding ) + $x ];
		}
		$raw = $ll . $raw;
	}

	if ( ( $w == 16 ) && ( $h == 16 ) ) {
		return ie_icon16( $raw, $text, $encoding, $transport );
	} elsif ( ( $w == 32 ) && ( $h == 32 ) ) {
		return ie_icon32( $raw, $text, $encoding, $transport );
	} else {
		return ie_picture( $raw, $w, $h, $text, $encoding, $transport );
	}
}    # end sub ie_bmp

########################################################################
# NOKIA
########################################################################
#***********************************************************************

=item B<smart_message(...)>

@messages = smart_message ( destination_port, user_data )

Produce a Nokia Smart Messages with application port addressing scheme.

=cut

#-----------------------------------------------------------------------
sub smart_message {
	my ( $port, $data, $transport ) = @_;

	unless ( defined($data) ) {
		$data = '';
	}

	unless ( defined($transport) ) {
		$transport = TRANSPORT_ANY;
	}

	if ( length($data) + 7 <= 140 ) {
		# Fit in single message & Short UDH
		return [ { udh => "\x06\x05\x04" . $port . "\x00\x00", ud => $data, coding => COD_8BIT, transport => $transport } ];
	} else {
		# Messages Chain
		my $udh    = "\x0B\x05\x04" . $port . "\x00\x00\x00\x03";    # UDH with concatenation
		my $refnum = int( rand(256) );                               # Chain Reference Number
		my $qty    = int( length($data) / 128 );                     # Messages in Chain

		$qty++ if ( length($data) % 128 );

		if ( $qty > 255 ) {
			return __PACKAGE__->error("This doesn't fit anyway");
		}

		$udh .= pack( 'C*', $refnum, $qty );

		# Making Messages
		my $result = [];
		for ( my $i = 1 ; $i <= $qty ; $i++ ) {
			push( @{$result}, { udh => $udh . pack( 'C', $i ), ud => substr( $data, 128 * ( $i - 1 ), 128 ), coding => COD_8BIT, transport => $transport } );
		}

		return $result;
	} ## end else [ if ( length($data) + 7...
}    # end sub smart_message

#***********************************************************************

=item B<smart_push_wap(...)>

http://www.devx.com/xml/Article/16754/1954?pf=true
http://www.w3.org/TR/wbxml/

=cut

#-----------------------------------------------------------------------
sub smart_push_wap {
	my ( $url, $title, $encoding, $transport ) = @_;

	unless ( defined($title) ) {
		$title = '';
	}

	if ( defined($encoding) and ( $title =~ m/[^\x00-\x7f]/ ) ) {
		$title = str_recode( $title, $encoding, to_enc => XML_ENCODING );
	}

	$url =~ s/^\w+:\/\///;

	my $data = "\xDC" .               # Push ID
	  "\x06" .                        # Push PDU
	  "\x01\xAE" .                    # Content-Type: application/vnd.wap.sic
	  "\x02\x05\x6A" .                # version / si / utf-8
	  "\x00\x45\xC6" .                # string / si / indication
	  "\x0C\x03" . $url . "\x00" .    # http:// zstring <url> \0
	  "\x01" .                        # Indication
	  "\x03" . $title . "\x00" .      # zstring <title> \0
	  "\x01\x01";                     # Indication / SI

	return smart_message( PORT_PUSHWAP, $data, $transport );
} ## end sub smart_push_wap

#***********************************************************************

=item B<smart_bmp(...)>

=cut

#-----------------------------------------------------------------------
sub smart_bmp {
	my ($bmp) = @_;

	if ( substr( $bmp, 0, 2 ) ne 'BM' ) {
		return __PACKAGE__->error("Not a BMP");
	}

	if ( unpack( 'L', substr( $bmp, 30, 4 ) ) ) {
		return __PACKAGE__->error("Compressed BMP");
	}

	unless ( unpack( 'S', substr( $bmp, 28, 2 ) ) == 1 ) {
		return __PACKAGE__->error("Need 1bpp monochrome BMP");
	}

	my $w   = unpack( 'L', substr( $bmp, 18, 4 ) );
	my $h   = unpack( 'L', substr( $bmp, 22, 4 ) );
	my $ofs = unpack( 'L', substr( $bmp, 10, 4 ) );

	my @bitmap = split( //, substr( $bmp, $ofs, length $bmp ) );

	my $line = int( $w / 8 );
	$line++ if ( $w % 8 );    # Line Width in bytes

	my $padding = 0;
	$padding = 4 - $line % 4 if ( $line % 4 );    # Pad to 4x bytes

	my $hdr = "\x00" . pack( 'C*', $w, $h ) . "\x01";    # OTA Bitmap Header

	my $raw = '';
	for ( my $y = 0 ; $y < $h ; $y++ ) {
		my $ll = '';
		for ( my $x = 0 ; $x < $line ; $x++ ) {
			$ll .= ~$bitmap[ $y * ( $line + $padding ) + $x ];
		}
		$raw = $ll . $raw;
	}

	return $hdr . $raw;
}    # end sub smart_bmp

#***********************************************************************

=item B<smart_logo(...)>

http://www.cisco.com/univercd/cc/td/doc/product/software/ios124/124cg/hmwg_c/mwgfmcc.htm
http://users.zipworld.com.au/~rmills/MCCandMNCValues.htm
http://www.surfio.de/info/mcc_mnc/mcc_mnc_liste_5.html

MCC MNC   Land  ISO Vorwahl Netzbetreiber
255  01 Ukraine UA  380     Ukrainian Mobile Comms (UMC)
255  02 Ukraine UA  380     Ukrainian Radio Systems (WellCOM)
255  03 Ukraine UA  380     Kyivstar GSM
255  05 Ukraine UA  380     Golden Telecom LLC
255  06 Ukraine UA  380     Astelit (life:))

=cut

#-----------------------------------------------------------------------
sub smart_logo {
	my ( $bmp, $mcc, $mnc, $transport ) = @_;

	my $data = smart_bmp($bmp);
	unless ($data) {
		return $data;
	}

	$data = "\x30" . str2bcd($mcc) . str2bcd($mnc) . "\x0A" . $data;

	return smart_message( PORT_LOGO, $data, $transport );
}

#***********************************************************************

=item B<smart_card(...)>

=cut

#-----------------------------------------------------------------------
sub smart_card {
	my ( $bmp, $transport ) = @_;

	my $bitmap = smart_bmp($bmp);
	unless ($bitmap) {
		return $bitmap;
	}

	my $size = int( length($bitmap) );
	my $data = "\x30\x02" . pack( 'C*', int( $size / 256 ), $size % 256 ) . $bitmap;

	return smart_message( PORT_ITEMS, $data, $transport );
}

#***********************************************************************

=item B<smart_cli(...)>

=cut

#-----------------------------------------------------------------------
sub smart_cli {
	my ( $bmp, $transport ) = @_;

	my $data = smart_bmp($bmp);
	unless ($data) {
		return $data;
	}

	return smart_message( PORT_CLI, "\x30" . $data, $transport );
}

#***********************************************************************

=item B<smart_ringtone(...)>

=cut

#-----------------------------------------------------------------------
sub smart_ringtone {
	my ( $ringtone, $transport ) = @_;

	return smart_message( PORT_RINGTONE, $ringtone, $transport );
}

#***********************************************************************

=item B<smart_clear(...)>

Pure shamanism

=cut

#-----------------------------------------------------------------------
sub smart_clear {
	my ($transport) = @_;

	return [ { udh => "\x06\x05\x04\x15\x82\x00\x00", ud => "\x30\x00\x00\x00\x0A\x00\x00\x00\x01", coding => COD_8BIT, transport => defined($transport) ? $transport : TRANSPORT_ANY } ];
}

########################################################################
# SIEMENS
########################################################################
#***********************************************************************

=item B<siemens_header(...)>

=cut

#-----------------------------------------------------------------------
sub siemens_header {
	my ( $data_size, $reference_id, $packet_number, $number_of_packets, $object_size, $object_type, $object_name ) = @_;

	my $result = '//SEO';    # "//Siemens Exchange Object"
	$result .= pack( "C", SEO_VER );                 # SEO Version, uchar
	$result .= pack( "S", $data_size );              # Data Block Size, uint(2)
	$result .= pack( "L", $reference_id );           # Reference ID, ulong(4)
	$result .= pack( "S", $packet_number );          # This Packet Number, uint(2)
	$result .= pack( "S", $number_of_packets );      # Total Packets, uint(2)
	$result .= pack( "L", $object_size );            # ObjectSize, ulong(4)
	$result .= pack( "C", length($object_type) );    # Pascal-string length, uchar
	$result .= $object_type;                         # Object Type identifier ('bmp' or 'mid')
	$result .= pack( "C", length($object_name) );    # Pascal-string length, uchar
	$result .= $object_name;                         # Object Name

	return $result;
}

#***********************************************************************

=item B<siemens_message(...)>

=cut

#-----------------------------------------------------------------------
sub siemens_message {
	my ( $object, $object_type, $object_name, $transport ) = @_;

	# Calculating Maximum DataSize
	my $data_size         = SMS_SIZE - SEO_LEN - length($object_type) - length($object_name);
	my $object_size       = length($object);
	my $full_size         = $object_size;
	my $number_of_packets = 1;

	if ( $object_size > $data_size ) {
		# [Zero]-Padding
		my $padding = '';
		my $padl = $data_size - ( $object_size % $data_size );
		$padding .= SEO_FILL x $padl;
		$object    = $object . $padding;
		$full_size = length($object);
		# Number of Chunks in Stream
		$number_of_packets = $full_size / $data_size;
	} else {
		$data_size = length($object);
	}

	# Unique Reference ID
	my $reference_id = rand(0xFFFFFFFF);

	unless ( defined($transport) ) {
		$transport = TRANSPORT_ANY;
	}

	# Make SMSes
	my $stream = [];
	for ( my $packet_number = 1 ; $packet_number <= $number_of_packets ; $packet_number++ ) {
		my $sms = '';
		$sms .= siemens_header( $data_size, $reference_id, $packet_number, $number_of_packets, $object_size, $object_type, $object_name );
		$sms .= substr( $object, ( $packet_number - 1 ) * $data_size, $data_size );
		push( @{$stream}, { udh => '', ud => $sms, coding => COD_8BIT, transport => $transport } );
	}

	return $stream;
}    # end sub siemens_message

#***********************************************************************

=item B<siemens(...)>

@smses = siemens ( $data [, $name] )

Produce a SEO messages stream. $data can contain MIDI or BMP data.
$name looks like old plain filename. Can be omitted.

=cut

#-----------------------------------------------------------------------
sub siemens {
	my ( $object, $o_name, $transport ) = @_;

	unless ($object) {
		return $object;
	}

	my $sig = substr( $object, 0, 2 );

	my $o_type = $SIGN{$sig};
	unless ($o_type) {
		return $o_type;
	}

	unless ( defined($o_name) and ( $o_name ne '' ) ) {
		$o_name = 'Nib' . rand(1000) . '.' . $o_type;
	}

	return siemens_message( $object, $o_type, $o_name, $transport );
} ## end sub siemens

#***********************************************************************

=item B<split_text()> - ????????

Paramters: text string (utf-8), SMS coding

Returns: array of SMS hashrefs

This method implements text SMS splitting to send concatenated messages.  

=cut 

#-----------------------------------------------------------------------

sub split_text {

	my ( $text, $coding ) = @_;

	$text = str_decode($text);

	my @ret = ();

	if ( $coding eq COD_7BIT ) {

		if ( length($text) <= 160 ) {
			push @ret, { udh => undef, ud => $text, coding => COD_7BIT };
		} else {
			my $udh    = "\x05\x00\x03";
			my $refnum = int( rand(256) );
			my $qty    = ceil( length($text) / 153 );
			$udh .= pack( 'C*', $refnum, $qty );

			for ( my $i = 1 ; $i <= $qty ; $i++ ) {
				push @ret, { udh => $udh . pack( 'C', $i ), ud => substr( $text, 153 * ( $i - 1 ), 153 ), coding => COD_7BIT };
			}
		}

	} elsif ( $coding eq COD_UNICODE ) {

		$text = str_encode($text);
		$text = str_decode( $text, "UTF-16BE" );

		if ( length($text) <= 140 ) {
			push @ret, ( { udh => undef, ud => $text, coding => COD_UNICODE } );
		} else {
			my $udh    = "\x05\x00\x03";
			my $refnum = int( rand(256) );

			my $qty = ceil( length($text) / 134 );
			$udh .= pack( 'C*', $refnum, $qty );

			for ( my $i = 1 ; $i <= $qty ; $i++ ) {
				my $part = substr( $text, 134 * ( $i - 1 ), 134 );
				$part = str_encode( $part, "UTF-16BE" );
				$part = str_decode( $part, "UTF-16BE" );
				push @ret, { udh => $udh . pack( 'C', $i ), ud => $part, coding => COD_UNICODE };
			}
		}

	} ## end elsif ( $coding eq COD_UNICODE)

	return @ret;

}    # end sub smart_message

#**************************************************************************
1;
__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Valentyn Solomko <pere@pere.org.ua>

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

