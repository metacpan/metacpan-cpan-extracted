/***************************************************************************
                          QtHelp4.xs  -  QtHelp perl extension
                             -------------------
    begin                : 10-12-2010
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

#include <qthelp_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qthelp(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtHelp4_handlers[];

static PerlQt4::Binding bindingqthelp;

MODULE = QtHelp4            PACKAGE = QtHelp4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i <= qthelp_Smoke->numClasses; i++) {
            if (qthelp_Smoke->classes[i].className && !qthelp_Smoke->classes[i].external)
                av_push(classList, newSVpv(qthelp_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qthelp_Smoke->numTypes; i++) {
            Smoke::Type curType = qthelp_Smoke->types[i];
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
#define boot_QtHelp4 boot_PerlQtHelp4
#endif

MODULE = QtHelp4            PACKAGE = QtHelp4

PROTOTYPES: ENABLE

BOOT:
    init_qthelp_Smoke();
    smokeList << qthelp_Smoke;

    bindingqthelp = PerlQt4::Binding(qthelp_Smoke);

    PerlQt4Module module = { "PerlQtHelp4", resolve_classname_qthelp, 0, &bindingqthelp  };
    perlqt_modules[qthelp_Smoke] = module;

    install_handlers(QtHelp4_handlers);
