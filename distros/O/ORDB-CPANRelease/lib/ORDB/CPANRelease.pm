package ORDB::CPANRelease;

use 5.008005;
use strict;
use warnings;
use Params::Util   0.38 ();
use ORLite::Mirror 1.12 ();

our $VERSION = '0.01';

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://devel.cpantesters.org/release/release.db.gz';
	$params->{maxage} ||= 24 * 60 * 60; # One day

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

1;
