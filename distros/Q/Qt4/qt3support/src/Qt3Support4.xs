/***************************************************************************
                          Qt3Support4.xs  -  Qt3Support perl extension
                             -------------------
    begin                : 09-02-2010
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

#include <qt3support_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qt3support(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler Qt3Support4_handlers[];

static PerlQt4::Binding bindingqt3support;

MODULE = Qt3Support4            PACKAGE = Qt3Support4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qt3support_Smoke->numClasses; i++) {
            if (qt3support_Smoke->classes[i].className && !qt3support_Smoke->classes[i].external)
                av_push(classList, newSVpv(qt3support_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qt3support_Smoke->numTypes; i++) {
            Smoke::Type curType = qt3support_Smoke->types[i];
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
#define boot_Qt3Support4 boot_PerlQt3Support4
#endif

MODULE = Qt3Support4            PACKAGE = Qt3Support4

PROTOTYPES: ENABLE

BOOT:
    init_qt3support_Smoke();
    smokeList << qt3support_Smoke;

    bindingqt3support = PerlQt4::Binding(qt3support_Smoke);

    PerlQt4Module module = { "PerlQt3Support4", resolve_classname_qt3support, 0, &bindingqt3support  };
    perlqt_modules[qt3support_Smoke] = module;

    install_handlers(Qt3Support4_handlers);
