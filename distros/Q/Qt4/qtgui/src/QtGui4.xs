/***************************************************************************
                          QtGui4.xs  -  QtGui perl extension
                             -------------------
    begin                : 03-29-2010
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
#include <QPolygonF>
#include <QPointF>
#include <QMetaObject>
#include <QMetaMethod>
#include <QVector>
#include <QtGui/QAbstractProxyModel>
#include <QtGui/QSortFilterProxyModel>
#include <QtGui/QDirModel>
#include <QtGui/QFileSystemModel>
#include <QtGui/QProxyModel>
#include <QtGui/QStandardItemModel>
#include <QtGui/QStringListModel>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <qtgui_smoke.h>

#include <smokeperl.h>
#include <handlers.h>
#include <util.h>
#include <listclass_macros.h>

extern Q_DECL_IMPORT QList<Smoke*> smokeList;
extern SV* sv_this;

const char*
resolve_classname_qtgui(smokeperl_object * o)
{
    return perlqt_modules[o->smoke].binding->className(o->classId);
}

extern TypeHandler QtGui4_handlers[];

static PerlQt4::Binding bindingqtgui;

DEF_LISTCLASS_FUNCTIONS(QItemSelection, QItemSelectionRange, QItemSelectionRange, Qt::ItemSelection)
DEF_VECTORCLASS_FUNCTIONS(QPolygonF, QPointF, Qt::PolygonF)
DEF_VECTORCLASS_FUNCTIONS(QPolygon, QPoint, Qt::Polygon)

MODULE = QtGui4            PACKAGE = QtGui4::_internal

PROTOTYPES: DISABLE

SV*
getClassList()
    CODE:
        AV* classList = newAV();
        for (int i = 1; i < qtgui_Smoke->numClasses; i++) {
            if (qtgui_Smoke->classes[i].className && !qtgui_Smoke->classes[i].external)
                av_push(classList, newSVpv(qtgui_Smoke->classes[i].className, 0));
        }
        RETVAL = newRV_noinc((SV*)classList);
    OUTPUT:
        RETVAL

#// args: none
#// returns: an array of all enum names that qtgui_Smoke knows about
SV*
getEnumList()
    CODE:
        AV *av = newAV();
        for(int i = 1; i < qtgui_Smoke->numTypes; i++) {
            Smoke::Type curType = qtgui_Smoke->types[i];
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
#define boot_QtGui4 boot_PerlQtGui4
#endif

MODULE = QtGui4            PACKAGE = QtGui4

PROTOTYPES: ENABLE

BOOT:
    init_qtgui_Smoke();
    smokeList << qtgui_Smoke;

    bindingqtgui = PerlQt4::Binding(qtgui_Smoke);

    PerlQt4Module module = { "PerlQtGui4", resolve_classname_qtgui, 0, &bindingqtgui  };
    perlqt_modules[qtgui_Smoke] = module;

    install_handlers(QtGui4_handlers);

    newXS(" Qt::PolygonF::EXISTS"   , XS_QPolygonF_exists, __FILE__);
    newXS(" Qt::PolygonF::FETCH"    , XS_QPolygonF_at, __FILE__);
    newXS(" Qt::PolygonF::FETCHSIZE", XS_QPolygonF_size, __FILE__);
    newXS(" Qt::PolygonF::STORE"    , XS_QPolygonF_store, __FILE__);
    newXS(" Qt::PolygonF::STORESIZE", XS_QPolygonF_storesize, __FILE__);
    newXS(" Qt::PolygonF::DELETE"   , XS_QPolygonF_delete, __FILE__);
    newXS(" Qt::PolygonF::CLEAR"    , XS_QPolygonF_clear, __FILE__);
    newXS(" Qt::PolygonF::PUSH"     , XS_QPolygonF_push, __FILE__);
    newXS(" Qt::PolygonF::POP"      , XS_QPolygonF_pop, __FILE__);
    newXS(" Qt::PolygonF::SHIFT"    , XS_QPolygonF_shift, __FILE__);
    newXS(" Qt::PolygonF::UNSHIFT"  , XS_QPolygonF_unshift, __FILE__);
    newXS(" Qt::PolygonF::SPLICE"   , XS_QPolygonF_splice, __FILE__);
    newXS("Qt::PolygonF::_overload::op_equality", XS_QPolygonF__overload_op_equality, __FILE__);

    newXS(" Qt::Polygon::EXISTS"   , XS_QPolygon_exists, __FILE__);
    newXS(" Qt::Polygon::FETCH"    , XS_QPolygon_at, __FILE__);
    newXS(" Qt::Polygon::FETCHSIZE", XS_QPolygon_size, __FILE__);
    newXS(" Qt::Polygon::STORE"    , XS_QPolygon_store, __FILE__);
    newXS(" Qt::Polygon::STORESIZE", XS_QPolygon_storesize, __FILE__);
    newXS(" Qt::Polygon::DELETE"   , XS_QPolygon_delete, __FILE__);
    newXS(" Qt::Polygon::CLEAR"    , XS_QPolygon_clear, __FILE__);
    newXS(" Qt::Polygon::PUSH"     , XS_QPolygon_push, __FILE__);
    newXS(" Qt::Polygon::POP"      , XS_QPolygon_pop, __FILE__);
    newXS(" Qt::Polygon::SHIFT"    , XS_QPolygon_shift, __FILE__);
    newXS(" Qt::Polygon::UNSHIFT"  , XS_QPolygon_unshift, __FILE__);
    newXS(" Qt::Polygon::SPLICE"   , XS_QPolygon_splice, __FILE__);
    newXS("Qt::Polygon::_overload::op_equality", XS_QPolygon__overload_op_equality, __FILE__);

    newXS(" Qt::ItemSelection::EXISTS"   , XS_QItemSelection_exists, __FILE__);
    newXS(" Qt::ItemSelection::FETCH"    , XS_QItemSelection_at, __FILE__);
    newXS(" Qt::ItemSelection::FETCHSIZE", XS_QItemSelection_size, __FILE__);
    newXS(" Qt::ItemSelection::STORE"    , XS_QItemSelection_store, __FILE__);
    newXS(" Qt::ItemSelection::STORESIZE", XS_QItemSelection_storesize, __FILE__);
    newXS(" Qt::ItemSelection::DELETE"   , XS_QItemSelection_delete, __FILE__);
    newXS(" Qt::ItemSelection::CLEAR"    , XS_QItemSelection_clear, __FILE__);
    newXS(" Qt::ItemSelection::PUSH"     , XS_QItemSelection_push, __FILE__);
    newXS(" Qt::ItemSelection::POP"      , XS_QItemSelection_pop, __FILE__);
    newXS(" Qt::ItemSelection::SHIFT"    , XS_QItemSelection_shift, __FILE__);
    newXS(" Qt::ItemSelection::UNSHIFT"  , XS_QItemSelection_unshift, __FILE__);
    newXS(" Qt::ItemSelection::SPLICE"   , XS_QItemSelection_splice, __FILE__);
    newXS("Qt::ItemSelection::_overload::op_equality", XS_QItemSelection__overload_op_equality, __FILE__);
