package Ogre::HardwareBufferManager;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::HardwareBufferManager::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'BufferLicenseType' => [qw(
		BLT_MANUAL_RELEASE
		BLT_AUTOMATIC_RELEASE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
