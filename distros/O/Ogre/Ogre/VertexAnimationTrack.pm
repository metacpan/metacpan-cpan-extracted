package Ogre::VertexAnimationTrack;

use strict;
use warnings;

use Ogre::AnimationTrack;
our @ISA = qw(Ogre::AnimationTrack);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::VertexAnimationTrack::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'TargetMode' => [qw(
		TM_SOFTWARE
		TM_HARDWARE
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
