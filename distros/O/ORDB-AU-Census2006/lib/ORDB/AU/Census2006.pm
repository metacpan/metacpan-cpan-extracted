package ORDB::AU::Census2006;

use 5.008005;
use strict;
use warnings;
use Params::Util   0.38 ();
use ORLite::Mirror 1.12 ();

our $VERSION = '0.01';

sub import {
	my $class = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://ali.as/census/census.sqlite.gz';
	$params->{maxage} ||= 7 * 24 * 60 * 60; # One week

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

1;
