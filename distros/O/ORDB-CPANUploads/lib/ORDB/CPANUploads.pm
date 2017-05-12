package ORDB::CPANUploads;

use 5.008005;
use strict;
use warnings;
use DateTime       0.55 ();
use Params::Util   1.00 ();
use ORLite::Mirror 1.20 ();

our $VERSION = '1.08';
our @LOCATION = (
	locale    => 'C',
	time_zone => 'UTC',
);

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://devel.cpantesters.org/uploads/uploads.db.bz2';
	$params->{maxage} ||= 7 * 24 * 60 * 60; # One week

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params );

	return 1;
}

sub latest {
	my $class = shift;

	# Find the most recent upload
	my @latest = ORDB::CPANUploads::Uploads->select(
		'ORDER BY released DESC LIMIT 1',
	);
	unless ( @latest == 1 ) {
		die "Unexpected number of uploads";
	}

	# When was the most recent release
	$latest[0]->released;
}

sub latest_datetime {
	my $class  = shift;
	return DateTime->from_epoch(
		epoch => $class->latest,
		@LOCATION,
	);
}

sub age {
	my $class    = shift;
	my $latest   = $class->latest_datetime;
	my $today    = DateTime->today( @LOCATION );
	my $duration = $today - $latest;
	return $duration->in_units('days');
}

1;
