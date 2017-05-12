package Ogre::AL::Sound;

use strict;
use warnings;

require Exporter;
use Ogre::MovableObject;
our @ISA = qw(Ogre::MovableObject Exporter);


our %EXPORT_TAGS = (
	'Priority' => [qw(
		LOW
		NORMAL
		HIGH
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();


1;

__END__
