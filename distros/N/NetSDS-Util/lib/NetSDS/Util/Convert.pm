#===============================================================================
#
#         FILE:  Convert.pm
#
#  DESCRIPTION:  Conversion between different data formats
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  17.08.2008 17:01:48 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::Convert - data formats conversion functions

=head1 SYNOPSIS

	use NetSDS::Util::Convert qw(...);

=head1 DESCRIPTION

C<NetSDS::Util::Convert> module contains miscelaneous functions.

=over

=item * CLI parameters processing

=item * types validation

=item * HEX, Base64, URI, BCD encondig

=item * UUID processing

=back

=cut

package NetSDS::Util::Convert;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '1.044';

our @EXPORT = qw(
  conv_str_bcd
  conv_chr_hex
  conv_hex_chr
  conv_str_hex
  conv_hex_str
  conv_str_base64
  conv_base64_str
  conv_str_uri
  conv_uri_str
);

use MIME::Base64;
use URI::Escape;

#***********************************************************************

=head1 EXPORTED FUNCTIONS

=over

=item B<conv_conv_str_bcd($str)> - convert string to little-endian BCD 

This function converts string to little-endian BCD encoding
filled with F16 value.

=cut

#-----------------------------------------------------------------------
sub conv_conv_str_bcd {
	my ($str) = @_;

	$str = "$str" . 'F' x ( length("$str") % 2 );
	$str =~ s/([\dF])([\dF])/$2$1/g;
	return conv_hex_str($str);
}

#***********************************************************************

=item B<conv_chr_hex($char)> - encode char to hexadecimal string

	$hex = conv_chr_hex('a'); # return 61

=cut

#-----------------------------------------------------------------------
sub conv_chr_hex {
	my ($chr) = @_;

	return defined($chr) ? uc( unpack( "H2", "$chr" ) ) : "$chr";
}

#***********************************************************************

=item B<conv_hex_chr($hex)> - convert hexadecimal string to character

	$chr = conv_hex_chr('4A'); # return 'J'

=cut

#-----------------------------------------------------------------------
sub conv_hex_chr {
	my ($hex) = @_;

	return defined($hex) ? pack( "H2", "$hex" ) : "$hex";
}

#***********************************************************************

=item B<conv_str_hex($str)> - convert byte string to hexadecimal 

	$str = 'Want hex dump!';
	$hex = conv_hex_str($str);
	print "Hex string: " . $hex;

=cut

#-----------------------------------------------------------------------
sub conv_str_hex {
	my ($str) = @_;

	return defined($str) ? uc( unpack( "H*", "$str" ) ) : "";
}

#***********************************************************************

=item B<conv_hex_str($string)> - convert hex to byte string

	$hex = '7A686F7061';
	$string = conv_hex_str($hex);
	print "String from hex: " . $string;

=cut

#-----------------------------------------------------------------------
sub conv_hex_str {
	my ($hex) = @_;

	return defined($hex) ? pack( "H*", "$hex" ) : "";    #"$hex";
}

#***********************************************************************

=item B<conv_str_base64($str)> - convert string to Base64 

	my $b64 = str_base64("Hallo, people!");

=cut 

#-----------------------------------------------------------------------

sub conv_str_base64 {

	my ($str) = @_;

	return encode_base64($str, "");

}

#***********************************************************************

=item B<conv_base64_str($b64)> - convert Base64 to string

	my $str = base64_str($base64_string);

=cut 

#-----------------------------------------------------------------------

sub conv_base64_str {

	my ($str) = @_;

	return decode_base64($str);

}

#***********************************************************************

=item B<conv_str_uri($str)> - convert string to URI encoded 

Example: 

	my $uri = str_uri("http://www.google.com/?q=what");

=cut 

#-----------------------------------------------------------------------

sub conv_str_uri {

	my ($str) = @_;

	return uri_escape( $str, "\x00-\xff" );

}

#***********************************************************************

=item B<conv_uri_str($uri)> - decode URI encoded string

Example: 

	my $str = uri_str($uri_string);

=cut 

#-----------------------------------------------------------------------

sub conv_uri_str {

	my ($str) = @_;

	return uri_unescape($str);

}

1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

None

=head1 TODO

1. Add other encodings support

=head1 SEE ALSO

L<Pod::Usage>, L<Data::UUID>

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
