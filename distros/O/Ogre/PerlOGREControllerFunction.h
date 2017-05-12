#ifndef _PERLOGRE_CONTROLLERFUNCTION_H_
#define _PERLOGRE_CONTROLLERFUNCTION_H_

#include "PerlOGRECallback.h"

class PerlOGREControllerFunction : public PerlOGRECallback, public Ogre::ControllerFunction<Ogre::Real>
{
 public:
    PerlOGREControllerFunction(SV *pobj);

    Ogre::Real calculate(Ogre::Real sourceValue);
};


#endif  /* define _PERLOGRE_CONTROLLERFUNCTION_H_ */
