package Ogre::AnimableValue;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::AnimableValue::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'ValueType' => [qw(
		INT
		REAL
		VECTOR2
		VECTOR3
		VECTOR4
		QUATERNION
		COLOUR
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
