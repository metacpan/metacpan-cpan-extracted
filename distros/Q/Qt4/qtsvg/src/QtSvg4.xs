/***************************************************************************
                          QtSvg4.xs  -  QtSvg perl extension
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

#include <qtsvg_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qtsvg(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtSvg4_handlers[];

static PerlQt4::Binding bindingqtsvg;

MODULE = QtSvg4            PACKAGE = QtSvg4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtsvg_Smoke->numClasses; i++) {
            if (qtsvg_Smoke->classes[i].className && !qtsvg_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtsvg_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtsvg_Smoke->numTypes; i++) {
            Smoke::Type curType = qtsvg_Smoke->types[i];
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
#define boot_QtSvg4 boot_PerlQtSvg4
#endif

MODULE = QtSvg4            PACKAGE = QtSvg4

PROTOTYPES: ENABLE

BOOT:
    init_qtsvg_Smoke();
    smokeList << qtsvg_Smoke;

    bindingqtsvg = PerlQt4::Binding(qtsvg_Smoke);

    PerlQt4Module module = { "PerlQtSvg4", resolve_classname_qtsvg, 0, &bindingqtsvg  };
    perlqt_modules[qtsvg_Smoke] = module;

    install_handlers(QtSvg4_handlers);
