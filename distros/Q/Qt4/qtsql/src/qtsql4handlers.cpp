/***************************************************************************
                          qtsql4handlers.cpp  -  QtSql specific marshallers
                             -------------------
    begin                : 06-19-2010
    copyright            : (C) 2010 Chris Burel
    email                : chrisburel@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either vesion 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include <QtCore/QHash>
#include <QPalette>
#include <QMetaObject>
#include <QMetaMethod>
#include <QLinkedList>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include <smokeperl.h>
#include <marshall_macros.h>

TypeHandler QtSql4_handlers[] = {
    { 0, 0 } //end of list
};
