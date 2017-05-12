package Ogre::Pass;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Pass::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'BuiltinHashFunction' => [qw(
		MIN_TEXTURE_CHANGE
		MIN_GPU_PROGRAM_CHANGE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
