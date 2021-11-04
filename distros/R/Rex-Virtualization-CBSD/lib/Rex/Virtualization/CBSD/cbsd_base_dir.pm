#
# (c) Zane C. Bowers-Hadley <vvelox@vvelox.net>
#

package Rex::Virtualization::CBSD::cbsd_base_dir;

use strict;
use warnings;

our $VERSION = '0.0.1';    # VERSION

use Rex::Logger;
use Rex::Helper::Run;
use Term::ANSIColor qw(colorstrip);
use Rex::Commands::User;

sub execute {
	my ($class) = @_;

	Rex::Logger::debug("Geting the CBSD base dir ");

	my %cbsd;
	eval{
		%cbsd= get_user('cbsd');
	} or do{
		my $error = $@ || 'Unknown failure';
		die ( "get_user('cbsd') died with... ".$error );
	};

	return $cbsd{home};
}

1;
