package Ogre::SceneQuery;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::SceneQuery::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'WorldFragmentType' => [qw(
		WFT_NONE
		WFT_PLANE_BOUNDED_REGION
		WFT_SINGLE_INTERSECTION
		WFT_CUSTOM_GEOMETRY
		WFT_RENDER_OPERATION
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
