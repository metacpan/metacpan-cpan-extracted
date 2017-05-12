package Ogre::Resource;

use strict;
use warnings;

use Ogre::StringInterface;
our @ISA = qw(Ogre::StringInterface);


########## GENERATED CONSTANTS BEGIN
require Exporter;
unshift @Ogre::Resource::ISA, 'Exporter';

our %EXPORT_TAGS = (
	'LoadingState' => [qw(
		LOADSTATE_UNLOADED
		LOADSTATE_LOADING
		LOADSTATE_LOADED
		LOADSTATE_UNLOADING
	)],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();
########## GENERATED CONSTANTS END
1;

__END__
