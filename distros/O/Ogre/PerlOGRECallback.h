#ifndef _PERLOGRE_CALLBACK_H_
#define _PERLOGRE_CALLBACK_H_

#include "perlOGRE.h"
#include <map>
#include <string>
#include <vector>

using namespace std;

// this is a baseclass for the other listeners

class PerlOGRECallback
{
 public:
    PerlOGRECallback(SV *pobj);
    ~PerlOGRECallback();

 protected:
    bool perlCallbackCan(string const &cbmeth);
    bool callPerlCallback(string const &cbmeth) const;
    Ogre::Real callPerlCallbackReal(string const &cbmeth) const;
    void callPerlCallbackVoid(string const &cbmeth) const;

    SV * mPerlObj;

    typedef vector<SV *> CBArgList;
    mutable CBArgList mCallbackArgs;

    typedef map<string, bool> CBCanMap;
    mutable CBCanMap mCanMap;
};


#endif  /* define _PERLOGRE_CALLBACK_H_ */
