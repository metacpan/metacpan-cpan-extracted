package Ogre::BetaGUI;

use strict;
use warnings;

our $VERSION = '0.04';

use Ogre 0.36;   # can only be used in an Ogre app


# the rest is for exporting the constants of the 'wt' enum (not really even used...)

require Exporter;
unshift @Ogre::BetaGUI::ISA, 'Exporter';

use constant {
    NONE => 0,
    MOVE => 1,
    RESIZE => 2,
    RESIZE_AND_MOVE => 3,
};

our %EXPORT_TAGS = (
    wt => [qw(NONE MOVE RESIZE RESIZE_AND_MOVE)],
);
$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();


1;
