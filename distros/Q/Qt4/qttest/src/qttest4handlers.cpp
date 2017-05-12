/***************************************************************************
                          qttest4handlers.cpp  -  QtTest specific marshallers
                             -------------------
    begin                : 07-12-2009
    copyright            : (C) 2010 Chris Burel
    email                : chrisburel@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either veqtruby_project_template.rbrsion 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QtCore/QHash>
#include <QPalette>
#include <QMetaObject>
#include <QMetaMethod>
#include <QLinkedList>

#include <QtTest/qtestaccessible.h>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <smokeperl.h>
#include <marshall_macros.h>

DEF_VALUELIST_MARSHALLER( QTestAccessibilityEventList, QList<QTestAccessibilityEvent>, QTestAccessibilityEvent )

TypeHandler QtTest4_handlers[] = {
    { "QList<QTestAccessibilityEvent>", marshall_QTestAccessibilityEventList },
    { 0, 0 } //end of list
};
