package Ogre::Image;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Image::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'Filter' => [qw(
		FILTER_NEAREST
		FILTER_LINEAR
		FILTER_BILINEAR
		FILTER_BOX
		FILTER_TRIANGLE
		FILTER_BICUBIC
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
