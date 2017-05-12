/***************************************************************************
                          qtgui4handlers.cpp  -  QtGui specific marshallers
                             -------------------
    begin                : 03-29-2010
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
#include <QVector>
#include <QMetaObject>
#include <QMetaMethod>
#include <QPalette>
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

//DEF_VALUELIST_MARSHALLER( QTestAccessibilityEventList, QList<QTestAccessibilityEvent>, QTestAccessibilityEvent )

TypeHandler QtGui4_handlers[] = {
    //{ "QList<QTestAccessibilityEvent>", marshall_QTestAccessibilityEventList },
    { "QFlags<QAbstractSpinBox::StepEnabledFlag>&", marshall_it< unsigned int *> },
    { "QFlags<QPaintEngine::DirtyFlag>&", marshall_it< unsigned int *> },
    { "QFlags<QPaintEngine::PaintEngineFeature>&", marshall_it< unsigned int *> },
    { "QFlags<QStyle::StateFlag>&", marshall_it< unsigned int *> },
    { "QFlags<QStyle::SubControl>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionButton::ButtonFeature>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionFrameV2::FrameFeature>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionTab::CornerWidget>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionToolBar::ToolBarFeature>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionToolButton::ToolButtonFeature>&", marshall_it< unsigned int *> },
    { "QFlags<QStyleOptionViewItemV2::ViewItemFeature>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::AlignmentFlag>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::DropAction>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::KeyboardModifier>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::MouseButton>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::TouchPointState>&", marshall_it< unsigned int *> },
    { "QFlags<Qt::WindowType>&", marshall_it< unsigned int *> },
    { 0, 0 }
};
