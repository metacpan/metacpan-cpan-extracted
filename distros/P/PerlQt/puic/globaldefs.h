/**********************************************************************
** Copyright (C) 2000 Trolltech AS.  All rights reserved.
**
** This file is part of Qt Designer.
**
** This file may be distributed and/or modified under the terms of the
** GNU General Public License version 2 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://www.trolltech.com/gpl/ for GPL licensing information.
**
** Contact info@trolltech.com if any conditions of this licensing are
** not clear to you.
**
**********************************************************************/

#ifndef GLOBALDEFS_H
#define GLOBALDEFS_H

#include <qcolor.h>

#define BOXLAYOUT_DEFAULT_MARGIN 11
#define BOXLAYOUT_DEFAULT_SPACING 6

#ifndef NO_STATIC_COLORS
static QColor *backColor1 = 0;
static QColor *backColor2 = 0;
static QColor *selectedBack = 0;

static void init_colors()
{
    if ( backColor1 )
	return;
    backColor1 = new QColor( 236, 245, 255 );
    backColor2 = new QColor( 250, 250, 250 );
    selectedBack = new QColor( 221, 221, 221 );
}

#endif

#endif
