MODULE = Ogre     PACKAGE = Ogre::TimeIndex

TimeIndex *
TimeIndex::new(Real timePos, ...)
  CODE:
    if (items == 2) {
        RETVAL = new TimeIndex(timePos);
    }
    else if (items == 3 && looks_like_number(ST(2))) {
        unsigned int keyIndex = (unsigned int)SvUV(ST(2));
        RETVAL = new TimeIndex(timePos, keyIndex);
    }
  OUTPUT:
    RETVAL

bool
TimeIndex::hasKeyIndex()

Real
TimeIndex::getTimePos()

unsigned int
TimeIndex::getKeyIndex()
