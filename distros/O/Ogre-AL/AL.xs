#include "OgreAL.h"

#include "perlOgreAL.h"

using namespace Ogre;
using namespace OgreAL;


MODULE = Ogre::AL		PACKAGE = Ogre::AL

PROTOTYPES: ENABLE



INCLUDE: perl -e "print qq{INCLUDE: \$_\$/} for <xs/*.xs>" |


BOOT:
    {
	HV *stash_OgreAL_Sound = gv_stashpv("Ogre::AL::Sound", TRUE);

	// enum: Priority
	newCONSTSUB(stash_OgreAL_Sound, "LOW", newSViv(Sound::LOW));
	newCONSTSUB(stash_OgreAL_Sound, "NORMAL", newSViv(Sound::NORMAL));
	newCONSTSUB(stash_OgreAL_Sound, "HIGH", newSViv(Sound::HIGH));
    }
