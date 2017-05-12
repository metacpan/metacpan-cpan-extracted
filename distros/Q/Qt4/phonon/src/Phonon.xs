/***************************************************************************
                          Phonon.xs  -  Phonon perl extension
                             -------------------
    begin                : 11-14-2010
    copyright            : (C) 2010 by Chris Burel
    email                : chrisburel@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QHash>
#include <QList>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <phonon_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;
extern SV* sv_this;

const char*
resolve_classname_phonon(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler Phonon_handlers[];

static PerlQt4::Binding bindingphonon;

MODULE = Phonon            PACKAGE = Phonon::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < phonon_Smoke->numClasses; i++) {
            if (phonon_Smoke->classes[i].className && !phonon_Smoke->classes[i].external)
                av_push(classList, newSVpv(phonon_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < phonon_Smoke->numTypes; i++) {
            Smoke::Type curType = phonon_Smoke->types[i];
            if( (curType.flags & Smoke::tf_elem) == Smoke::t_enum )
                av_push(av, newSVpv(curType.name, 0));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

#// The build system with cmake and mingw relies on the visibility being set for
#// a dll to export that symbol.  So we need to redefine XSPROTO so that we can
#// export the boot method.
#ifdef WIN32
#undef XSPROTO
#define XSPROTO(name) void Q_DECL_EXPORT name(pTHX_ CV* cv)
#define boot_Phonon boot_PerlPhonon
#endif

MODULE = Phonon            PACKAGE = Phonon

PROTOTYPES: ENABLE

BOOT:
    init_phonon_Smoke();
    smokeList << phonon_Smoke;

    bindingphonon = PerlQt4::Binding(phonon_Smoke);

    PerlQt4Module module = { "PerlPhonon", resolve_classname_phonon, 0, &bindingphonon  };
    perlqt_modules[phonon_Smoke] = module;

    install_handlers(Phonon_handlers);
