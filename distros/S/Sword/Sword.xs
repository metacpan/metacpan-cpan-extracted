#include <swmgr.h>
#include <swmodule.h>
#include <markupfiltmgr.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

using namespace sword;

typedef SWKey    Sword_Key;
typedef SWMgr    Sword_Manager;
typedef SWModule Sword_Module;

MODULE = Sword                  PACKAGE = Sword::Key

Sword_Key *
Sword_Key::clone()
    CODE:
        RETVAL = THIS->clone();
    OUTPUT:
        RETVAL

void
Sword_Key::set_text(const char *key)
    CODE:
        THIS->setText(key);

const char *
Sword_Key::get_text()
    CODE:
        RETVAL = THIS->getText();
    OUTPUT:
        RETVAL

const char *
Sword_Key::get_short_text()
    CODE:
        RETVAL = THIS->getShortText();
    OUTPUT:
        RETVAL

const char *
Sword_Key::get_range_text()
    CODE:
        RETVAL = THIS->getRangeText();
    OUTPUT:
        RETVAL

int
Sword_Key::compare(Sword_Key *other_key)
    CODE:
        RETVAL = THIS->compare(*other_key);
    OUTPUT:
        RETVAL

bool
Sword_Key::equals(Sword_Key *other_key)
    CODE:
        RETVAL = THIS->equals(*other_key);
    OUTPUT:
        RETVAL

void
Sword_Key::increment(int steps = 1)
    CODE:
        THIS->increment(steps);

void
Sword_Key::decrement(int steps = 1)
    CODE:
        THIS->decrement(steps);

void
Sword_Key::top()
    CODE:
        THIS->setPosition(TOP);

void
Sword_Key::bottom()
    CODE:
        THIS->setPosition(BOTTOM);

long
Sword_Key::index(long new_index = -1)
    CODE:
        if (new_index != -1)
            RETVAL = THIS->Index(new_index);
        else
            RETVAL = THIS->Index();
    OUTPUT:
        RETVAL

MODULE = Sword                  PACKAGE = Sword::Manager

Sword_Manager *
Sword_Manager::new()
    CODE:
        RETVAL = new SWMgr(new MarkupFilterMgr(FMT_PLAIN));
    OUTPUT:
        RETVAL

AV *
Sword_Manager::modules()
    CODE:
        RETVAL = newAV();
        sv_2mortal((SV *)RETVAL);

        ModMap::iterator module;
        for (module = THIS->Modules.begin(); module != THIS->Modules.end(); ++module) {
	    // FIXME (*module).first is a SWBuf... no idea what that is yet...
	    // so I'm going to ignore it for now... :-D
	    SWModule *swmod = (*module).second;
            SV *module = newSV(0);
	    sv_setref_pv(module, "Sword::Module", (void *)swmod);
            av_push(RETVAL, module);
        }

    OUTPUT:
        RETVAL

Sword_Module *
Sword_Manager::get_module(const char *name)
    CODE:
        RETVAL = THIS->getModule(name);
        if (!RETVAL) XSRETURN_UNDEF;
    
    OUTPUT:
        RETVAL

MODULE = Sword                  PACKAGE = Sword::Module

const char *
Sword_Module::name(const char *name = 0)
    CODE:
        if (name)
            RETVAL = THIS->Name(name);
        else
            RETVAL = THIS->Name();
    OUTPUT:
    	RETVAL

const char *
Sword_Module::description(const char *description = 0)
    CODE:
        if (description)
            RETVAL = THIS->Description(description);
        else 
            RETVAL = THIS->Description();
    OUTPUT:
        RETVAL

const char *
Sword_Module::type(const char *type = 0)
    CODE:
        if (type)
            RETVAL = THIS->Type(type);
        else 
            RETVAL = THIS->Type();
    OUTPUT:
        RETVAL

void
Sword_Module::increment(int steps = 1)
    CODE:
        THIS->increment(steps);

void
Sword_Module::decrement(int steps = 1)
    CODE:
        THIS->decrement(steps);

void
Sword_Module::top()
    CODE:
        THIS->setPosition(TOP);

void
Sword_Module::bottom()
    CODE:
        THIS->setPosition(BOTTOM);

void
Sword_Module::set_key(SV *key)
    CODE:
        if (sv_derived_from(key, "Sword::Key")) {
            IV tmp = SvIV((SV *)SvRV(key));
            SWKey *swkey = INT2PTR(SWKey *, tmp);
            THIS->setKey(swkey);
        }
        else {
            STRLEN len;
            char *skey = SvPV(key, len);
            THIS->setKey(skey);
        }

Sword_Key *
Sword_Module::create_key()
    CODE:
        RETVAL = THIS->CreateKey();
    OUTPUT:
        RETVAL

Sword_Key *
Sword_Module::get_key()
    CODE:
        RETVAL = THIS->getKey();
    OUTPUT:
        RETVAL

const char *
Sword_Module::strip_text()
    CODE:
        RETVAL = THIS->StripText();
    OUTPUT:
        RETVAL

const char *
Sword_Module::render_text()
    CODE:
        RETVAL = THIS->RenderText();
    OUTPUT:
        RETVAL


