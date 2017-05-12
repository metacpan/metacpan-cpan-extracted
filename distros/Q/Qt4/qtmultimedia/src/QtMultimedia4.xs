/***************************************************************************
                          QtMultimedia4.xs  -  QtMultimedia perl extension
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

#include <qtmultimedia_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qtmultimedia(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtMultimedia4_handlers[];

static PerlQt4::Binding bindingqtmultimedia;

MODULE = QtMultimedia4            PACKAGE = QtMultimedia4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtmultimedia_Smoke->numClasses; i++) {
            if (qtmultimedia_Smoke->classes[i].className && !qtmultimedia_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtmultimedia_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtmultimedia_Smoke->numTypes; i++) {
            Smoke::Type curType = qtmultimedia_Smoke->types[i];
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
#define boot_QtMultimedia4 boot_PerlQtMultimedia4
#endif

MODULE = QtMultimedia4            PACKAGE = QtMultimedia4

PROTOTYPES: ENABLE

BOOT:
    init_qtmultimedia_Smoke();
    smokeList << qtmultimedia_Smoke;

    bindingqtmultimedia = PerlQt4::Binding(qtmultimedia_Smoke);

    PerlQt4Module module = { "PerlQtMultimedia4", resolve_classname_qtmultimedia, 0, &bindingqtmultimedia  };
    perlqt_modules[qtmultimedia_Smoke] = module;

    install_handlers(QtMultimedia4_handlers);
