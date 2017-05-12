#ifndef _PERLOGRE_FRAMELISTENER_H_
#define _PERLOGRE_FRAMELISTENER_H_

#include "PerlOGRECallback.h"

using namespace std;

// this class implements Ogre::FrameListener,
// so it can be passed to Root->addFrameListener
// but still allowing implementing the callbacks from Perl

class PerlOGREFrameListener : public PerlOGRECallback, public Ogre::FrameListener
{
 public:
    PerlOGREFrameListener(SV *pobj);

    // FrameListener interface
    bool frameStarted(const Ogre::FrameEvent &evt);
    bool frameEnded(const Ogre::FrameEvent &evt);
};


#endif  /* define _PERLOGRE_FRAMELISTENER_H_ */
