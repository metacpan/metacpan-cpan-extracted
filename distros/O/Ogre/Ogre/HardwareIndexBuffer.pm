package Ogre::HardwareIndexBuffer;

use strict;
use warnings;

use Ogre::HardwareBuffer;
our @ISA = qw(Ogre::HardwareBuffer);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::HardwareIndexBuffer::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'IndexType' => [qw(
		IT_16BIT
		IT_32BIT
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
