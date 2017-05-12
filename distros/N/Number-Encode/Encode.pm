package Number::Encode;

require 5.005_62;
use strict;
use warnings;
use Digest::MD5 qw(md5);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(nonuniform uniform) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '1.00';

sub uniform ($) {
    my $data = shift;
    my $char = 0;
    my $carry = 0;
    my $cbits = 0;
    my $hsh = '';

    for my $c (split(//, $data))
    {
	
	$carry <<= 8;
	$carry += ord($c);
	$cbits += 8;

	while ($cbits >= 4) {

	    my $n;

	    if ($cbits >= 4) {	# More than 4 bits available
		$n = $carry & 0xF;
		if ($n > 9) {
		    $n ^= vec(md5($hsh . $carry . $n), $n, 4);
		    $n &= 0x7 if $n > 9;
		}
		$carry >>= 4;
		$cbits -= 4;
	    }

	    $hsh .= chr(ord('0') + $n);
	}
    }

    if ($cbits) {
	$hsh .= chr(ord('0') + $carry);
    }

    return $hsh;
}

sub nonuniform ($) {
    my $data = shift;
    my $char = 0;
    my $carry = 0;
    my $cbits = 0;
    my $hsh = '';

    for my $c (split(//, $data))
    {
	$carry <<= 256;
	$carry += ord($c);
	$cbits += 8;

	while ($cbits >= 4) {

	    my $n;

	    if ($cbits >= 4) {	# More than 4 bits available
		$n = $carry & 0xF;
		if ($n <= 9) {
		    $carry >>= 4;
		    $cbits -= 4;
		}
	    }

	    if ($cbits == 3 or $n > 9) {
		$n = $carry & 0x7;
		$carry >>= 3;
		$cbits -= 3;
	    }
	    $hsh .= chr(ord('0') + $n);
	}
    }

    if ($cbits) {
	$hsh .= chr(ord('0') + $carry);
    }

    return $hsh;
}

1;
__END__

=head1 NAME

Number::Encode - Encode bit strings into digit strings

=head1 SYNOPSIS

  use Number::Encode qw(nonuniform uniform);

=head1 DESCRIPTION

Provides  a mechanism  to convert  arbitrary bit-strings  into numeric
digit  strings.  The  transformation  can be  uniform  or  non-uniform
depending on the type of distribution of the numeric digits achieved.

The former  approach is useful for  security-related applications such
as  calling  cards  and  the  such,  which  require  a  uniform  digit
distribution.  The  algorythm used to  generate uniform distributions,
while deterministic, is more constly than the non-uniform variant.

This module is  distributed under the same terms  and warranty as Perl
itself.

=head2 EXPORT

This module provides the following exports:

=over

=item C<my $number = nonuniform($data)>

Converts  a  bit-string  represented  in  the example  by  the  scalar
C<$data>   to   a    numeric   string   representation   returned   at
C<$number>.

The probabilistic  distribution of the digits in  the resulting number
is not uniform. Some digits will have up to twice the chance of others
of appearing at a given position.

=item C<my $number = uniform($data)>

Performs a transformation from  the bit-string provided in C<$data> to
a numeric string returned at  C<$number>. This transformation is a bit
more  costly but  has the  advantage  that the  digit distribution  is
uniform.  This  function is adequate  for applications that  require a
uniform composition  of the numeric  strings, such as password  or PIN
number generators.

=back

=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXfn
	Number::Encode
	-v
	1.00

=back


=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>

=head1 SEE ALSO

perl(1).

=cut
