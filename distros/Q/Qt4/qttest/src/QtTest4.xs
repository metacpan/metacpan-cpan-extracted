/***************************************************************************
                          QtTest4.xs  -  QtTest perl extension
                             -------------------
    begin                : 07-12-2009
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
#include <QSignalSpy>
#include <QTestEventList>
#include <QVariant>
#include <QPalette>
#include <QMetaObject>
#include <QMetaMethod>
#include <QLinkedList>
#include <QtTest>

#include <iostream>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <qttest_smoke.h>

#include <smokeperl.h>
#include <handlers.h>
#include <util.h>
#include <listclass_macros.h>
#include <qtesteventlist_macros.h>

extern QList<Smoke*> smokeList;

const char*
resolve_classname_qttest(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtTest4_handlers[];

static PerlQt4::Binding bindingqttest;

DEF_LISTCLASS_FUNCTIONS(QSignalSpy, QList<QVariant>, QVariantList, Qt::SignalSpy)
DEF_QTESTEVENTLIST_FUNCTIONS(QTestEventList, QTestEvent, QTestEvent, Qt::TestEventList)

MODULE = QtTest4            PACKAGE = QtTest4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qttest_Smoke->numClasses; i++) {
            if (qttest_Smoke->classes[i].className && !qttest_Smoke->classes[i].external)
                av_push(classList, newSVpv(qttest_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qttest_Smoke->numTypes; i++) {
            Smoke::Type curType = qttest_Smoke->types[i];
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
#define boot_QtTest4 boot_PerlQtTest4
#endif

MODULE = QtTest4            PACKAGE = QtTest4

PROTOTYPES: ENABLE

BOOT:
    init_qttest_Smoke();
    smokeList << qttest_Smoke;

    bindingqttest = PerlQt4::Binding(qttest_Smoke);

    PerlQt4Module module = { "PerlQtTest4", resolve_classname_qttest, 0, &bindingqttest  };
    perlqt_modules[qttest_Smoke] = module;

    install_handlers(QtTest4_handlers);

    newXS(" Qt::SignalSpy::EXISTS"   , XS_QSignalSpy_exists, __FILE__);
    newXS(" Qt::SignalSpy::FETCH"    , XS_QSignalSpy_at, __FILE__);
    newXS(" Qt::SignalSpy::FETCHSIZE", XS_QSignalSpy_size, __FILE__);
    newXS(" Qt::SignalSpy::STORE"    , XS_QSignalSpy_store, __FILE__);
    newXS(" Qt::SignalSpy::STORESIZE", XS_QSignalSpy_storesize, __FILE__);
    newXS(" Qt::SignalSpy::DELETE"   , XS_QSignalSpy_delete, __FILE__);
    newXS(" Qt::SignalSpy::CLEAR"    , XS_QSignalSpy_clear, __FILE__);
    newXS(" Qt::SignalSpy::PUSH"     , XS_QSignalSpy_push, __FILE__);
    newXS(" Qt::SignalSpy::POP"      , XS_QSignalSpy_pop, __FILE__);
    newXS(" Qt::SignalSpy::SHIFT"    , XS_QSignalSpy_shift, __FILE__);
    newXS(" Qt::SignalSpy::UNSHIFT"  , XS_QSignalSpy_unshift, __FILE__);
    newXS(" Qt::SignalSpy::SPLICE"   , XS_QSignalSpy_splice, __FILE__);
    newXS("Qt::SignalSpy::_overload::op_equality", XS_QSignalSpy__overload_op_equality, __FILE__);

    newXS(" Qt::TestEventList::EXISTS"   , XS_QTestEventList_exists, __FILE__);
    newXS(" Qt::TestEventList::FETCH"    , XS_QTestEventList_at, __FILE__);
    newXS(" Qt::TestEventList::FETCHSIZE", XS_QTestEventList_size, __FILE__);
    newXS(" Qt::TestEventList::STORE"    , XS_QTestEventList_store, __FILE__);
    newXS(" Qt::TestEventList::STORESIZE", XS_QTestEventList_storesize, __FILE__);
    newXS(" Qt::TestEventList::CLEAR"    , XS_QTestEventList_clear, __FILE__);
    newXS(" Qt::TestEventList::PUSH"     , XS_QTestEventList_push, __FILE__);
    newXS(" Qt::TestEventList::POP"      , XS_QTestEventList_pop, __FILE__);
    newXS(" Qt::TestEventList::SHIFT"    , XS_QTestEventList_shift, __FILE__);
    newXS(" Qt::TestEventList::UNSHIFT"  , XS_QTestEventList_unshift, __FILE__);
    newXS(" Qt::TestEventList::SPLICE"   , XS_QTestEventList_splice, __FILE__);
    newXS("Qt::TestEventList::_overload::op_equality", XS_QTestEventList__overload_op_equality, __FILE__);
