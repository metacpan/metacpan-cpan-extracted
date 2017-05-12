MODULE = Ogre     PACKAGE = Ogre::TextureManager

static TextureManager *
TextureManager::getSingletonPtr()

## note: all the ResourceManager subclasses need to override 'load' like this
Texture *
TextureManager::load(String name, String group, int texType=TEX_TYPE_2D, int numMipmaps=MIP_DEFAULT, Real gamma=1.0f, bool isAlpha=false, int desiredFormat=PF_UNKNOWN)
  CODE:
    RETVAL = THIS->load(name, group, (TextureType)texType, numMipmaps, gamma, isAlpha, (PixelFormat)desiredFormat).getPointer();
  OUTPUT:
    RETVAL


void
TextureManager::setDefaultNumMipmaps(size_t num)
