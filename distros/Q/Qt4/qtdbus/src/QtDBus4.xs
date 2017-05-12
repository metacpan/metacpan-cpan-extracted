/***************************************************************************
                          QtDBus4.xs  -  QtDBus perl extension
                             -------------------
    begin                : 06-19-2010
    copyright            : (C) 2009 by Chris Burel
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
#include <QDBusVariant>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <qtdbus_smoke.h>

#include <smokeperl.h>
#include <handlers.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qtdbus(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

bool
slot_returnvalue_dbus(Smoke::ModuleIndex classId, void** o, Smoke::Stack stack) {
    if ( !strcmp(qtdbus_Smoke->classes[classId.index].className, "QDBusVariant") ) {
        *reinterpret_cast<QDBusVariant*>(o[0]) = *(QDBusVariant*) stack[0].s_class;
        return true;
    }
    return false;
}

extern TypeHandler QtDBus4_handlers[];

static PerlQt4::Binding bindingqtdbus;

MODULE = QtDBus4            PACKAGE = QtDBus4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtdbus_Smoke->numClasses; i++) {
            if (qtdbus_Smoke->classes[i].className && !qtdbus_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtdbus_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtdbus_Smoke->numTypes; i++) {
            Smoke::Type curType = qtdbus_Smoke->types[i];
            if( (curType.flags & Smoke::tf_elem) == Smoke::t_enum )
                av_push(av, newSVpv(curType.name, 0));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

MODULE = QtDBus4            PACKAGE = QtDBus4

PROTOTYPES: ENABLE

BOOT:
    init_qtdbus_Smoke();
    smokeList << qtdbus_Smoke;

    bindingqtdbus = PerlQt4::Binding(qtdbus_Smoke);

    PerlQt4Module module = { "PerlQtDBus4", resolve_classname_qtdbus, 0, &bindingqtdbus, slot_returnvalue_dbus  };
    perlqt_modules[qtdbus_Smoke] = module;

    install_handlers(QtDBus4_handlers);
