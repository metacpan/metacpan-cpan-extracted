MODULE = Ogre::AL   PACKAGE = Ogre::AL::SoundManager

static SoundManager *
SoundManager::getSingletonPtr()

SoundManager *
SoundManager::new(...)
  CODE:
    if (items == 1) {
        RETVAL = new OgreAL::SoundManager();
    }
    else if (items == 2) {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String deviceName = xstmpchr;
        RETVAL = new OgreAL::SoundManager(deviceName);
    }
  OUTPUT:
    RETVAL

## Hmm... when getSingletonPtr is called, this eventually destroys
## the SoundManager, which is not desirable
##void
##SoundManager::DESTROY()

Sound *
SoundManager::createSound(String name, String fileName, bool loop=false, bool stream=false)

Sound *
SoundManager::getSound(String name)

bool
SoundManager::hasSound(String name)

void
SoundManager::destroySound(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Sound")) {
        Sound *sound = (Sound *) SvIV((SV *) SvRV(ST(1)));
        THIS->destroySound(sound);
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        THIS->destroySound(name);
    }

void
SoundManager::destroyAllSounds()

void
SoundManager::pauseAllSounds()

void
SoundManager::resumeAllSounds()

Listener *
SoundManager::getListener()

## I think this is not needed
## bool frameStarted(const Ogre::FrameEvent& evt);

void
SoundManager::setDopplerFactor(Real dopplerFactor)

Real
SoundManager::getDopplerFactor()

void
SoundManager::setSpeedOfSound(Real speedOfSound)

Real
SoundManager::getSpeedOfSound()

## XXX: need to return aref of strings
## static Ogre::StringVector getDeviceList();

## FormatMapIterator getSupportedFormatIterator();

## XXX: need to wrap FormatData class
## const FormatData* retrieveFormatData(AudioFormat format) const;

int
SoundManager::maxSources()

int
SoundManager::eaxSupport()

bool
SoundManager::xRamSupport()

## ALboolean eaxSetBufferMode(Size numBuffers, BufferRef *buffers, EAXMode bufferMode)
## ALenum SoundManager::eaxGetBufferMode(BufferRef buffer, ALint *reserved = 0)

## xxx: some const String and ALenum
