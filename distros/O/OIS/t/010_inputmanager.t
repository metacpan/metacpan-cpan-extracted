#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('OIS');
    use_ok('OIS::InputManager');
}


# pretty lame tests, but these methods are useless anyway

like(OIS::InputManager->getVersionNumber(), qr/^\d+$/, 'check getVersionNumber');

## the API changed here...
#like(OIS::InputManager->getVersionName(), qr/^.+$/, 'check getVersionName');


# XXX: I don't know how to test createInputSystem and destroyInputSystem
# without using Ogre. Consequently, I also don't know how to test the
# object methods like numMice, etc., or createInputObject (note: there are
# three methods in the Perl wrapping: createInputObjectMouse,
# createInputObjectKeyboard, and createInputObjectJoyStick
