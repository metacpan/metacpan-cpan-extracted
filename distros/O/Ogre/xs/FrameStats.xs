MODULE = Ogre     PACKAGE = Ogre::RenderTarget::FrameStats

# I cant get this to work.
# RenderTarget::FrameStats, not FrameStats.
# However, you can use methods from RenderTarget (RenderWindow) instead.

## These are "public attributes", not methods.

#Real
#FrameStats::lastFPS()
#  CODE:
#    RETVAL = (*THIS).lastFPS;
#  OUTPUT:
#    RETVAL
#
#Real
#FrameStats::avgFPS()
#  CODE:
#    RETVAL = (*THIS).avgFPS;
#  OUTPUT:
#    RETVAL
#
#Real
#FrameStats::bestFPS()
#  CODE:
#    RETVAL = (*THIS).bestFPS;
#  OUTPUT:
#    RETVAL
#
#Real
#FrameStats::worstFPS()
#  CODE:
#    RETVAL = (*THIS).worstFPS;
#  OUTPUT:
#    RETVAL
#
#unsigned long
#FrameStats::bestFrameTime()
#  CODE:
#    RETVAL = (*THIS).bestFrameTime;
#  OUTPUT:
#    RETVAL
#
#unsigned long
#FrameStats::worstFrameTime()
#  CODE:
#    RETVAL = (*THIS).worstFrameTime;
#  OUTPUT:
#    RETVAL
#
#size_t
#FrameStats::triangleCount()
#  CODE:
#    RETVAL = (*THIS).triangleCount;
#  OUTPUT:
#    RETVAL
#
#size_t
#FrameStats::batchCount()
#  CODE:
#    RETVAL = (*THIS).batchCount;
#  OUTPUT:
#    RETVAL
