package Ogre::Serializer;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Serializer::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'Endian' => [qw(
		ENDIAN_NATIVE
		ENDIAN_BIG
		ENDIAN_LITTLE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
