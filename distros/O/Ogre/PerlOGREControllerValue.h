#ifndef _PERLOGRE_CONTROLLERVALUE_H_
#define _PERLOGRE_CONTROLLERVALUE_H_

#include "PerlOGRECallback.h"

class PerlOGREControllerValue : public PerlOGRECallback, public Ogre::ControllerValue<Ogre::Real>
{
 public:
    PerlOGREControllerValue(SV *pobj);

    virtual Ogre::Real getValue() const;
    virtual void setValue(Ogre::Real value);
};


#endif  /* define _PERLOGRE_CONTROLLERVALUE_H_ */
