#===============================================================================
#
#         FILE:  Types.pm
#
#  DESCRIPTION:
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.044
#      CREATED:  17.08.2008 17:01:48 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::Types - type checking routines

=head1 SYNOPSIS

	use NetSDS::Util::Types;

	# Check if variable contains integer value
	if (is_int($var)) {
		$var++;
	} else {
		print "Value is not integer!";
	}

=head1 DESCRIPTION

C<NetSDS::Util::Types> module contains functions for
checking data for being of exact data types.

=cut

package NetSDS::Util::Types;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '1.044';

use POSIX;

use Scalar::Util qw(
  blessed
  reftype
);

our @EXPORT = qw(
  is_int
  is_float
  is_date
  is_binary
  is_ref_scalar
  is_ref_array
  is_ref_hash
  is_ref_code
  is_ref_obj
);

#***********************************************************************

=head1 EXPORTED FUNCTIONS

=over

=item B<is_int($var)> - check if parameter is integer

Check if given parameter is integer

=cut

#-----------------------------------------------------------------------
sub is_int {
	my ($value) = @_;

	return 0 unless defined $value;

	return ( ( $value =~ /^[-+]?\d+$/ ) and ( $value >= INT_MIN ) and ( $value <= INT_MAX ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_float([...])> - check if parameter is float number

Check if given parameter is float number

=cut

#-----------------------------------------------------------------------
sub is_float {
	my ($value) = @_;

	return 0 unless defined $value;

	#	return ( ( $value =~ m/^[-+]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([-+]?\d+))?$/ ) and ( ( $value >= 0 ) and ( $value >= DBL_MIN() ) and ( $value <= DBL_MAX() ) ) or ( ( $value < 0 ) and ( $value >= -DBL_MAX() ) and ( $value <= -DBL_MIN() ) ) ) ? 1 : 0;
	return ( $value =~ m/^[-+]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([-+]?\d+))?$/ ) ? 1 : 0;
}

#***********************************************************************

=item B<is_date([...])> - check if parameter is date string

Return 1 if parameter is date string

=cut

#-----------------------------------------------------------------------
sub is_date {
	my ($value) = @_;

	return 0 unless defined $value;

	return ( $value =~ m/^\d{8}T\d{2}:\d{2}:\d{2}(Z|[-+]\d{1,2}(?::\d{2})*)$/ ) ? 1 : 0;
}

#***********************************************************************

=item B<is_binary([...])> - check for binary content

Return 1 if parameter is non text.

=cut

#-----------------------------------------------------------------------
sub is_binary {
	my ($value) = @_;

	if ( has_utf8($value) ) {
		return 0;
	} else {
		return ( $value =~ m/[^\x09\x0a\x0d\x20-\x7f[:print:]]/ ) ? 1 : 0;
	}
}

#**************************************************************************

=item B<is_ref_scalar($ref)> - check if reference to scalar value

Return true if parameter is a scalar reference.

	my $var = 'Scalar string';
	if (is_ref_scalar(\$var)) {
		print "It's scalar value";
	}

=cut

#-----------------------------------------------------------------------
sub is_ref_scalar {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'SCALAR' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_array($ref)> - check if reference to array

Return true if parameter is an array reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_array {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'ARRAY' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_hash($ref)> - check if hashref

Return true if parameter is a hash reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_hash {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'HASH' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_code($ref)> - check if code reference

Return true if parameter is a code reference.

=cut

#-----------------------------------------------------------------------
sub is_ref_code {
	my $ref = reftype( $_[0] );

	return ( $ref and ( $ref eq 'CODE' ) ) ? 1 : 0;
}

#***********************************************************************

=item B<is_ref_obj($ref, [$class_name])> - check if blessed object

Return true if parameter is an object.

=cut

#-----------------------------------------------------------------------
sub is_ref_obj {
	return blessed( $_[0] ) ? 1 : 0;
}

1;
__END__

=back

=head1 EXAMPLES

None

=head1 BUGS

None

=head1 TODO

Add more functions.

=head1 SEE ALSO

None.

=head1 AUTHORS

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut
