package Ogre::CompositionPass;

use strict;
use warnings;


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::CompositionPass::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'PassType' => [qw(
		PT_CLEAR
		PT_STENCIL
		PT_RENDERSCENE
		PT_RENDERQUAD
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
