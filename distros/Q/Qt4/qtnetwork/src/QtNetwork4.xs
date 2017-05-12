/***************************************************************************
                          QtNetwork4.xs  -  QtNetwork perl extension
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

#include <qtnetwork_smoke.h>

#include <smokeperl.h>
#include <handlers.h>
#include "xsfunctions.h"

extern QList<Smoke*> smokeList;
extern SV* sv_this;

const char*
resolve_classname_qtnetwork(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtNetwork4_handlers[];

static PerlQt4::Binding bindingqtnetwork;

MODULE = QtNetwork4            PACKAGE = QtNetwork4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtnetwork_Smoke->numClasses; i++) {
            if (qtnetwork_Smoke->classes[i].className && !qtnetwork_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtnetwork_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtnetwork_Smoke->numTypes; i++) {
            Smoke::Type curType = qtnetwork_Smoke->types[i];
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
#define boot_QtNetwork4 boot_PerlQtNetwork4
#endif

MODULE = QtNetwork4            PACKAGE = QtNetwork4

PROTOTYPES: ENABLE

#ifdef WIN32
#undef XSPROTO
#define XSPROTO(name) void Q_DECL_EXPORT name(pTHX_ CV* cv)
#endif

BOOT:
    init_qtnetwork_Smoke();
    smokeList << qtnetwork_Smoke;

    bindingqtnetwork = PerlQt4::Binding(qtnetwork_Smoke);

    PerlQt4Module module = { "PerlQtNetwork4", resolve_classname_qtnetwork, 0, &bindingqtnetwork  };
    perlqt_modules[qtnetwork_Smoke] = module;

    install_handlers(QtNetwork4_handlers);
    newXS(" Qt::UdpSocket::readDatagram", XS_qudpsocket_readdatagram, __FILE__);
