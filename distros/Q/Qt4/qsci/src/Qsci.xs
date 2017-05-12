/***************************************************************************
                          Qsci.xs  -  Qsci perl extension
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

#include <qsci_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;
extern SV* sv_this;

const char*
resolve_classname_qsci(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler Qsci_handlers[];

static PerlQt4::Binding bindingqsci;

MODULE = Qsci            PACKAGE = Qsci::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qsci_Smoke->numClasses; i++) {
            if (qsci_Smoke->classes[i].className && !qsci_Smoke->classes[i].external)
                av_push(classList, newSVpv(qsci_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qsci_Smoke->numTypes; i++) {
            Smoke::Type curType = qsci_Smoke->types[i];
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
#define boot_Qsci boot_PerlQsci
#endif

MODULE = Qsci            PACKAGE = Qsci

PROTOTYPES: ENABLE

BOOT:
    init_qsci_Smoke();
    smokeList << qsci_Smoke;

    bindingqsci = PerlQt4::Binding(qsci_Smoke);

    PerlQt4Module module = { "PerlQsci", resolve_classname_qsci, 0, &bindingqsci  };
    perlqt_modules[qsci_Smoke] = module;

    install_handlers(Qsci_handlers);
