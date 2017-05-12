#ifndef _PERLOIS_JOYSTICKLISTENER_H_
#define _PERLOIS_JOYSTICKLISTENER_H_

#include "perlOIS.h"
#include <map>
#include <string>

using namespace std;

// this class implements OIS::JoyStickListener,
// so it can be passed to JoyStick->setEventCallback,
// but it allows implementing the callbacks from Perl

class PerlOISJoyStickListener : public OIS::JoyStickListener
{
 public:
    PerlOISJoyStickListener();
    ~PerlOISJoyStickListener();

    // these are used in xs/JoyStickboard.xs setEventCallback
    void setPerlObject(SV *pobj);

    // JoyStickListener interface
    bool buttonPressed(const OIS::JoyStickEvent &evt, int button);
    bool buttonReleased(const OIS::JoyStickEvent &evt, int button);
    bool axisMoved(const OIS::JoyStickEvent &evt, int axis);
    bool sliderMoved(const OIS::JoyStickEvent &evt, int slider);
    bool povMoved(const OIS::JoyStickEvent &evt, int pov);

 private:
    bool perlCallbackCan(string const &cbmeth);
    void setCans();
    bool callPerlCallback(string const &cbmeth, const OIS::JoyStickEvent &evt, int id);

    SV * mPerlObj;

    typedef map<string, bool> CanMap;
    CanMap mCanMap;
};


#endif  /* define _PERLOIS_JOYSTICKLISTENER_H_ */
