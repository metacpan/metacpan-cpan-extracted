MODULE = Ogre     PACKAGE = Ogre::SkeletonManager

static SkeletonManager *
SkeletonManager::getSingletonPtr()

## xxx: all the ResourceManager subclasses need to override 'load' like this
## xxx: skipped last arg, NameValuePairList
Skeleton *
SkeletonManager::load(String name, String group, bool isManual=false, ManualResourceLoader *loader=0)
  CODE:
    SkeletonPtr skel = THIS->load(name, group, isManual, loader);
    RETVAL = skel.getPointer();
  OUTPUT:
    RETVAL
