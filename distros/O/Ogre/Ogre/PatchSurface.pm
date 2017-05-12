package Ogre::PatchSurface;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::PatchSurface::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'PatchSurfaceType' => [qw(
		PST_BEZIER
	)],
	'._100' => [qw(
		AUTO_LEVEL
	)],
	'VisibleSide' => [qw(
		VS_FRONT
		VS_BACK
		VS_BOTH
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
