MODULE = Ogre     PACKAGE = Ogre::MaterialManager

static MaterialManager *
MaterialManager::getSingletonPtr()

## xxx: all the ResourceManager subclasses need to override 'load' like this
## xxx: skipped last arg, NameValuePairList
Material *
MaterialManager::load(String name, String group, bool isManual=false, ManualResourceLoader *loader=0)
  CODE:
    MaterialPtr mat = THIS->load(name, group, isManual, loader);
    RETVAL = mat.getPointer();
  OUTPUT:
    RETVAL


void
MaterialManager::initialise()

## xxx: does DataStream have be handled with a filehandle ?
void
MaterialManager::parseScript(DataStream *stream, String groupName)
  CODE:
    DataStreamPtr strmPtr = DataStreamPtr(stream);
    THIS->parseScript(strmPtr, groupName);

void
MaterialManager::setDefaultTextureFiltering(...)
  CODE:
    if (items == 2) {
        THIS->setDefaultTextureFiltering((TextureFilterOptions) SvIV(ST(1)));
    }
    else if (items == 3) {
        THIS->setDefaultTextureFiltering((FilterType) SvIV(ST(1)), (FilterOptions) SvIV(ST(2)));
    }
    else if (items == 4) {
        THIS->setDefaultTextureFiltering((FilterOptions) SvIV(ST(1)), (FilterOptions) SvIV(ST(2)), (FilterOptions) SvIV(ST(3)));
    }

int
MaterialManager::getDefaultTextureFiltering(int ftype)
  C_ARGS:
    (FilterType)ftype

void
MaterialManager::setDefaultAnisotropy(unsigned int maxAniso)

unsigned int
MaterialManager::getDefaultAnisotropy()

Material *
MaterialManager::getDefaultSettings()
  CODE:
    RETVAL = THIS->getDefaultSettings().getPointer();
  OUTPUT:
    RETVAL

String
MaterialManager::getActiveScheme()

void
MaterialManager::setActiveScheme(String schemeName)
