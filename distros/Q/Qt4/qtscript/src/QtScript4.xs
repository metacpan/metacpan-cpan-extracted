/***************************************************************************
                          QtScript4.xs  -  QtScript perl extension
                             -------------------
    begin                : 06-19-2010
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

#include <qtscript_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qtscript(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtScript4_handlers[];

static PerlQt4::Binding bindingqtscript;

MODULE = QtScript4            PACKAGE = QtScript4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtscript_Smoke->numClasses; i++) {
            if (qtscript_Smoke->classes[i].className && !qtscript_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtscript_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtscript_Smoke->numTypes; i++) {
            Smoke::Type curType = qtscript_Smoke->types[i];
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
#define boot_QtScript4 boot_PerlQtScript4
#endif

MODULE = QtScript4            PACKAGE = QtScript4

PROTOTYPES: ENABLE

BOOT:
    init_qtscript_Smoke();
    smokeList << qtscript_Smoke;

    bindingqtscript = PerlQt4::Binding(qtscript_Smoke);

    PerlQt4Module module = { "PerlQtScript4", resolve_classname_qtscript, 0, &bindingqtscript  };
    perlqt_modules[qtscript_Smoke] = module;

    install_handlers(QtScript4_handlers);
