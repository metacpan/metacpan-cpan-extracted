MODULE = Ogre     PACKAGE = Ogre::SceneQuery

void
SceneQuery::setQueryMask(uint32 mask)

uint32
SceneQuery::getQueryMask()

void
SceneQuery::setQueryTypeMask(uint32 mask)

uint32
SceneQuery::getQueryTypeMask()

void
SceneQuery::setWorldFragmentType(int wft)
  C_ARGS:
    (SceneQuery::WorldFragmentType)wft

int
SceneQuery::getWorldFragmentType()

## virtual const set<WorldFragmentType>::type* Ogre::SceneQuery::getSupportedWorldFragmentTypes(void) const
## note: this just returns a list
void
SceneQuery::getSupportedWorldFragmentTypes()
  PPCODE:
    const Ogre::set<SceneQuery::WorldFragmentType>::type *wfts = THIS->getSupportedWorldFragmentTypes();
    Ogre::set<SceneQuery::WorldFragmentType>::type::const_iterator it;
    for (it = wfts->begin(); it != wfts->end(); it++) {
        mXPUSHi((int) *it);
    }
