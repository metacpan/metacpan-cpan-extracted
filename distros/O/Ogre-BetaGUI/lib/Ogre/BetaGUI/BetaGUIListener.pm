package Ogre::BetaGUI::BetaGUIListener;

### Note: this was ported to Perl from:
# /// Betajaen's GUI 016 Uncompressed
# /// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
# /// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
###

use strict;
use warnings;

use Ogre 0.33;


sub new {
    my ($pkg) = @_;

    my $self = bless {}, $pkg;
    return $self;
}

sub onButtonPress {
    die __PACKAGE__ . ": subclasses must implement 'onButtonPress'\n";
}


1;
