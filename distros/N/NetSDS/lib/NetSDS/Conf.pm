#===============================================================================
#
#         FILE:  Conf.pm
#
#  DESCRIPTION:  Configuration handling via command line and Config::General
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  16.05.2008 12:24:55 EEST
#===============================================================================

=head1 NAME

NetSDS::Conf - API to configuration files

=head1 SYNOPSIS

	use NetSDS::Conf;

	my $cf = NetSDS::Conf->getconf($conf_file);
	my $val = $cf->{'parameter'};

=head1 DESCRIPTION

B<NetSDS::Conf> module is a wrapper to B<Config::General> handler for
NetSDS configuration files.

This package is for internal usage and is called from B<NetSDS::App>
or inherited modules and should be never used directly from applications.

=cut

package NetSDS::Conf;

use 5.8.0;
use strict;
use warnings;

use Config::General;

use version; our $VERSION = '1.301';

#***********************************************************************

=over

=item B<getconf()> - read parameters from configuration file

Paramters: configuration file name

Returns: cofiguration as hash reference

This method tries to read configuration file and fill object properties
with read values.

NOTE: Parameters set from command line will not be overriden.

=cut 

#-----------------------------------------------------------------------

sub getconf {

	my ( $proto, $cf ) = @_;

	# Check if configuration file available for reading and read data
	if ( $cf and ( -f $cf ) and ( -r $cf ) ) {

		my $conf = Config::General->new(
			-ConfigFile        => $cf,
			-AllowMultiOptions => 'yes',
			-UseApacheInclude  => 'yes',
			-InterPolateVars   => 'yes',
			-ConfigPath        => [ $ENV{NETSDS_CONF_DIR}, '/etc/NetSDS' ],
			-IncludeRelative   => 'yes',
			-IncludeGlob       => 'yes',
			-UTF8              => 'yes',
		);

		# Parse configuration file
		my %cf_hash = $conf->getall;

		return \%cf_hash;

	} else {
		return undef;
	}

} ## end sub getconf

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown

=head1 SEE ALSO

L<Getopt::Long>, L<Config::General>, L<NetSDS::Class::Abstract>

=head1 TODO

1. Improve documentation.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


