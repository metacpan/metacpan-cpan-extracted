MODULE = Ogre     PACKAGE = Ogre::ResourceManager

## xxx: skipped last arg, NameValuePairList
Resource *
ResourceManager::create(String name, String group, bool isManual=false, ManualResourceLoader *loader=0)
  CODE:
    RETVAL = THIS->create(name, group, isManual, loader).getPointer();
  OUTPUT:
    RETVAL

## xxx:
## ResourceCreateOrRetrieveResult ResourceManager::createOrRetrieve(String name, String group, bool isManual=false, ManualResourceLoader *loader=0, const NameValuePairList *createParams=0)

void
ResourceManager::setMemoryBudget(size_t bytes)

size_t
ResourceManager::getMemoryBudget()

size_t
ResourceManager::getMemoryUsage()

void
ResourceManager::unload(...)
  CODE:
    if (looks_like_number(ST(1))) {
        THIS->unload((Ogre::ResourceHandle) SvUV(ST(1)));
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        THIS->unload(name);
    }

void
ResourceManager::unloadAll(bool reloadableOnly=true)

void
ResourceManager::reloadAll(bool reloadableOnly=true)

void
ResourceManager::unloadUnreferencedResources(bool reloadableOnly=true)

void
ResourceManager::reloadUnreferencedResources(bool reloadableOnly=true)

void
ResourceManager::remove(...)
  CODE:
    if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Resource")) {
        Resource *r = (Resource *) SvIV((SV *) SvRV(ST(1)));   // TMOGRE_IN
        ResourcePtr rptr = ResourcePtr(r);
        THIS->remove(rptr);
    }
    else if (looks_like_number(ST(1))) {
        THIS->remove((Ogre::ResourceHandle) SvUV(ST(1)));
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        THIS->remove(name);
    }

void
ResourceManager::removeAll()

Resource *
ResourceManager::getByName(String name)
  CODE:
    RETVAL = THIS->getByName(name).getPointer();
  OUTPUT:
    RETVAL

Resource *
ResourceManager::getByHandle(ResourceHandle handle)
  CODE:
    RETVAL = THIS->getByHandle(handle).getPointer();
  OUTPUT:
    RETVAL

bool
ResourceManager::resourceExists(...)
  CODE:
    if (looks_like_number(ST(1))) {
        RETVAL = THIS->resourceExists((Ogre::ResourceHandle) SvUV(ST(1)));
    }
    else {
        char * xstmpchr = (char *) SvPV_nolen(ST(1));
        String name = xstmpchr;
        RETVAL = THIS->resourceExists(name);
    }
  OUTPUT:
    RETVAL

## xxx: skipped last arg, NameValuePairList
Resource *
ResourceManager::load(String name, String group, bool isManual=false, ManualResourceLoader *loader=0)
  CODE:
    RETVAL = THIS->load(name, group, isManual, loader).getPointer();
  OUTPUT:
    RETVAL

## const StringVector & ResourceManager::getScriptPatterns()

void
ResourceManager::parseScript(DataStream *stream, String groupName)
  CODE:
    DataStreamPtr streamptr = DataStreamPtr(stream);
    THIS->parseScript(streamptr, groupName);

Real
ResourceManager::getLoadingOrder()

String
ResourceManager::getResourceType()

## ResourceMapIterator ResourceManager::getResourceIterator()
