#include "PerlOGRECallbackManager.h"
#include <string>

using namespace std;


PerlOGRECallbackManager::PerlOGRECallbackManager()
{
}

PerlOGRECallbackManager::~PerlOGRECallbackManager()
{
    // clean up addFrameListener
    for (FrameListenerMap::iterator it = mFrameListenerMap.begin(); it != mFrameListenerMap.end(); ++it) {
        delete it->second;
    }
    mFrameListenerMap.clear();

    // clean up addWindowEventListener
    mWinEvtListenerWindowMMap.clear();
    for (WinEvtListenerMap::iterator it = mWinEvtListenerMap.begin(); it != mWinEvtListenerMap.end(); ++it) {
        delete it->second;
    }
    mWinEvtListenerMap.clear();
}

void PerlOGRECallbackManager::addFrameListener(SV *pobj, Ogre::Root *root)
{
    if (sv_isobject(pobj)) {
        PerlOGREFrameListener *fl = new PerlOGREFrameListener(pobj);

        HV *stash = SvSTASH(SvRV(pobj));
        string pkgname(HvNAME(stash));

        // add to the manager
        // (note: won't insert if pkgname already has a listener,
        //  that's how maps work)
        pair<FrameListenerMap::iterator, bool> insertPair;
        insertPair = mFrameListenerMap.insert(FrameListenerMap::value_type(pkgname, static_cast<Ogre::FrameListener *>(fl)));

        if (insertPair.second) {
            // add to Root if inserting worked (i.e. didn't already exist)
            root->addFrameListener(fl);
        } else {
            warn("FrameListener %s not added (probably already added)\n", pkgname.c_str());
        }
    } else {
        croak("Argument to addFrameListener has to be an object\n");
    }
}

void PerlOGRECallbackManager::removeFrameListener(SV *pobj, Ogre::Root *root)
{
    // get package name from object
    HV *stash = SvSTASH(SvRV(pobj));
    string pkgname(HvNAME(stash));

    FrameListenerMap::iterator it = mFrameListenerMap.find(pkgname);
    if (it != mFrameListenerMap.end()) {
        // remove from Root
        root->removeFrameListener(it->second);

        // remove from the manager
        delete it->second;
        mFrameListenerMap.erase(it);
    } else {
        warn("removeFrameListener: %s didn't have a FrameListener, so not removed",
             pkgname.c_str());
    }
}

void PerlOGRECallbackManager::addWindowEventListener(SV *pobj, Ogre::RenderWindow *win)
{
    if (sv_isobject(pobj)) {
        PerlOGREWindowEventListener *wel = new PerlOGREWindowEventListener(pobj);

        // As with FrameListener, we keep track of the Perl pkgname for each
        // C++ listener

        HV *stash = SvSTASH(SvRV(pobj));
        string pkgname(HvNAME(stash));

        mWinEvtListenerMap.insert(WinEvtListenerMap::value_type(pkgname, static_cast<Ogre::WindowEventListener *>(wel)));


        // Now, we can have multiple listeners per window,
        // and multiple windows per listener,
        // so we also keep track of which Windows are associated
        // with each Perl package

        // find out if pkg is already mapped to this win;
        // if so, don't insert and ignore all this
        bool doInsert = true;
        WinEvtListenerWindowMMap::iterator it = mWinEvtListenerWindowMMap.find(pkgname);
        while (it != mWinEvtListenerWindowMMap.end() && it->first == pkgname) {
            if (it->second == win) {
                doInsert = false;
                break;
            }
            ++it;
        }

        if (doInsert) {
            mWinEvtListenerWindowMMap.insert(WinEvtListenerWindowMMap::value_type(pkgname, win));

            // do the C++ (the whole point of this manager crap :)
            Ogre::WindowEventUtilities::addWindowEventListener(win, wel);
        }
    } else {
        croak("Argument to addWindowEventListener has to be an object\n");
    }
}

void PerlOGRECallbackManager::removeWindowEventListener(SV *pobj, Ogre::RenderWindow *win)
{
    HV *stash = SvSTASH(SvRV(pobj));
    string pkgname(HvNAME(stash));

    WinEvtListenerMap::iterator mit = mWinEvtListenerMap.find(pkgname);

    if (mit != mWinEvtListenerMap.end()) {
        // First remove the listener->window mapping
        WinEvtListenerWindowMMap::iterator mmit = mWinEvtListenerWindowMMap.find(pkgname);
        while (mmit != mWinEvtListenerWindowMMap.end() && mmit->first == pkgname) {
            if (mmit->second == win) {
                // do the C++ part
                Ogre::WindowEventUtilities::removeWindowEventListener(win, mit->second);

                // and take it out of the manager
                mWinEvtListenerWindowMMap.erase(mmit);
            }
            ++mmit;
        }

        // Also, if that was the last window, get rid of the
        // pkgname-listener mapping
        if (mWinEvtListenerWindowMMap.empty()) {
            delete mit->second;   // cleanup object created in addWindowEventListener
            mWinEvtListenerMap.erase(mit);
        }
    } else {
        warn("removeWindowEventListener: %s didn't have a WindowEventListener, so not removed",
             pkgname.c_str());
    }
}
