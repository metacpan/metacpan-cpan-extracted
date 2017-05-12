package Ogre::AxisAlignedBox;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::AxisAlignedBox::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'CornerEnum' => [qw(
		FAR_LEFT_BOTTOM
		FAR_LEFT_TOP
		FAR_RIGHT_TOP
		FAR_RIGHT_BOTTOM
		NEAR_RIGHT_BOTTOM
		NEAR_LEFT_BOTTOM
		NEAR_LEFT_TOP
		NEAR_RIGHT_TOP
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
