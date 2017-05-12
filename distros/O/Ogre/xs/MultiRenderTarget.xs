MODULE = Ogre     PACKAGE = Ogre::MultiRenderTarget

void
MultiRenderTarget::bindSurface(attachment, target)
    size_t attachment
    RenderTexture * target

void
MultiRenderTarget::unbindSurface(size_t attachment)

# note: this intentionally throws an exception
void
MultiRenderTarget::writeContentsToFile(filename)
    String  filename
