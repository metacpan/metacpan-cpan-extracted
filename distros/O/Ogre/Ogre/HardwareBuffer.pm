package Ogre::HardwareBuffer;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::HardwareBuffer::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'Usage' => [qw(
		HBU_STATIC
		HBU_DYNAMIC
		HBU_WRITE_ONLY
		HBU_DISCARDABLE
		HBU_STATIC_WRITE_ONLY
		HBU_DYNAMIC_WRITE_ONLY
		HBU_DYNAMIC_WRITE_ONLY_DISCARDABLE
	)],
	'LockOptions' => [qw(
		HBL_NORMAL
		HBL_DISCARD
		HBL_READ_ONLY
		HBL_NO_OVERWRITE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
