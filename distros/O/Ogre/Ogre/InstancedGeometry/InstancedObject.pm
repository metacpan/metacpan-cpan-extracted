package Ogre::InstancedGeometry::InstancedObject;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::InstancedGeometry::InstancedObject::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'TransformSpace' => [qw(
		TS_LOCAL
		TS_PARENT
		TS_WORLD
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
