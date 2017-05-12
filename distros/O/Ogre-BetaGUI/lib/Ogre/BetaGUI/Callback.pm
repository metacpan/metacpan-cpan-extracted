package Ogre::BetaGUI::Callback;

### Note: this was ported to Perl from:
# /// Betajaen's GUI 016 Uncompressed
# /// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
# /// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
###

use strict;
use warnings;
use Scalar::Util qw(blessed);

use Ogre 0.33;


sub new {
    my ($pkg, $arg) = @_;

    my $self = bless {
        t => 0,
        fp => undef,
        LS => undef,
    }, $pkg;

    if (defined $arg) {
        # this code ref has to accept two args (see BetaGUIListener onButtonPress)
        if (ref($arg) eq 'CODE') {
            $self->{t} = 1;
            $self->{fp} = $arg;
        }
        elsif (blessed($arg) && $arg->isa('Ogre::BetaGUI::BetaGUIListener')) {
            $self->{t} = 2;
            $self->{LS} = $arg;
        }
    }

    return $self;
}


1;
