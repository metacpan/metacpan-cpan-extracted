/***************************************************************************
                          QtOpenGL4.xs  -  QtOpenGL perl extension
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

#include <qtopengl_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qtopengl(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtOpenGL4_handlers[];

static PerlQt4::Binding bindingqtopengl;

MODULE = QtOpenGL4            PACKAGE = QtOpenGL4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtopengl_Smoke->numClasses; i++) {
            if (qtopengl_Smoke->classes[i].className && !qtopengl_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtopengl_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtopengl_Smoke->numTypes; i++) {
            Smoke::Type curType = qtopengl_Smoke->types[i];
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
#define boot_QtOpenGL4 boot_PerlQtOpenGL4
#endif

MODULE = QtOpenGL4            PACKAGE = QtOpenGL4

PROTOTYPES: ENABLE

BOOT:
    init_qtopengl_Smoke();
    smokeList << qtopengl_Smoke;

    bindingqtopengl = PerlQt4::Binding(qtopengl_Smoke);

    PerlQt4Module module = { "PerlQtOpenGL4", resolve_classname_qtopengl, 0, &bindingqtopengl  };
    perlqt_modules[qtopengl_Smoke] = module;

    install_handlers(QtOpenGL4_handlers);
