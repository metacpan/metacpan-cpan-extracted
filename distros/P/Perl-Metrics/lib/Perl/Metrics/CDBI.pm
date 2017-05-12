package Perl::Metrics::CDBI;

# The Perl::Metrics::CDBI class acts as a base class for the index and
# provides the integration with Class::DBI.
#
# It has no user-servicable parts at this time

use strict;
use base 'Class::DBI';
use Carp        ();
use DBI         ();
use DBD::SQLite ();

use vars qw{$VERSION $DSN};
BEGIN {
	$VERSION = '0.09';
	$DSN     = undef;
}





#####################################################################
# Class::DBI Methods

sub db_Main {
	# We must have the database location defined
	unless ( $DSN ) {
		Carp::croak("No DSN defined for Perl::Metrics::CDBI");
	}

	# Unless we use Class::DBI's attributes, the whole thing comes
	# tumbling horribly down around us. Yes, this completely sucks.
	my %attr = Class::DBI->_default_attributes;

	DBI->connect( $DSN, '', '', \%attr )
		or Carp::croak("Error connecting to Perl::Metrics database at $DSN");
}

1;
