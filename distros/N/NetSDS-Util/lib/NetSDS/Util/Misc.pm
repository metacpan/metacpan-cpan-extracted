#===============================================================================
#
#         FILE:  Misc.pm
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

NetSDS::Util::Misc - miscelaneous utilities

=head1 SYNOPSIS

	use NetSDS::Util::Misc;

=head1 DESCRIPTION

C<NetSDS::Util::Misc> module contains miscelaneous functions.

=cut

package NetSDS::Util::Misc;

use 5.8.0;
use warnings 'all';
use strict;

use base 'Exporter';

use version; our $VERSION = '1.044';

our @EXPORT = qw(
  cmp_version
  usage
  get_cli
  make_uuid
  csv_num
  format_msisdn
);

use Getopt::Long;
use Pod::Usage;
use Data::UUID;

#***********************************************************************

=head1 EXPORTED FUNCTIONS

=over

=item B<cmp_version($ver1, $ver2)> - compare versions

Funcion comapres two version strings.

=cut

#-----------------------------------------------------------------------
sub cmp_version {
	my ( $ver1, $ver2 ) = @_;

	return sprintf( "%03d.%03d", split( m/\./, $ver1 ) ) cmp sprintf( "%03d.%03d", split( m/\./, $ver2 ) );
}

#***********************************************************************

=item B<usage(...)> - print C<usage> text

This function is wapper to L<Pod::Usage> module printing POD to STDERR.

=cut

#-----------------------------------------------------------------------
sub usage {
	pod2usage(
		-message => sprintf( shift(@_), @_ ),
		-verbose => 0,
		-exitval => 2,
		-output  => \*STDERR
	);
}

#***********************************************************************

=item B<get_cli(...)> - get CLI parameters

Return command line arguments

=cut

#-----------------------------------------------------------------------
sub get_cli {
	my ( $res, @opa ) = @_;

	my $ret  = undef;
	my @argv = @ARGV;    # save @ARGV
	{
		# Switch off warnings because of other CLI parameters
		# still not known
		my $warn = $SIG{__WARN__};
		$SIG{__WARN__} = sub { };
		$ret = GetOptions( $res, @opa, 'help|h|?', 'man|m' );
		$SIG{__WARN__} = $warn;
	}
	@ARGV = @argv;       # restore @ARGV

	# GetOptions bug workaround
	#	if ( !$ret ) {
	#		pod2usage( -verbose => 0, -exitval => 2, -output => \*STDERR );
	#	} elsif ( exists( $res->{help} ) and $res->{help} ) {
	if ( exists( $res->{help} ) and $res->{help} ) {
		pod2usage( -verbose => 1, -exitval => 2, -output => \*STDERR );
	} elsif ( exists( $res->{man} ) and $res->{man} ) {
		pod2usage( -verbose => 2, -exitval => 2, -output => \*STDERR );
	}

	return $res;
} ## end sub get_cli

#***********************************************************************

=item B<make_uuid()> - make UUD string

Create upper case UUID string.

=cut

#-----------------------------------------------------------------------
sub make_uuid {

	return Data::UUID->new()->create_str();

}

#***********************************************************************

=item B<csv_num($num)> - format number for CSV 

Paramters: numeric value

Returns: CSV formatted

=cut 

sub csv_num {

	my ($num) = @_;
	$num =~ s/\./,/g;
	$num = "\"$num\"";

	return $num;
}

#***********************************************************************

=item B<format_msisdn($msisdn)> - format MSISDN

Paramters: phone number 

Returns: well formed MSISDN without leading +.

=cut 

#-----------------------------------------------------------------------

sub format_msisdn {

	my ($msisdn) = @_;

	$msisdn =~ s/[\-\(\)\.\s]//g;

	if ( $msisdn =~ /^\+?(\d{12})$/ ) {
		return $1;
	} elsif ( $msisdn =~ /^\s*(\d{9,12})\s*$/ ) {
		return "380" . substr( $msisdn, length($1) - 9, 9 );
	} else {
		return undef;
	}

}

#**************************************************************************
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
