/*
 * PerlQt interface to qpainter.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "ppainter.h"
#include "enum.h"

#define STORE_mode(mode) enumIV(hv, MSTR(mode), mode ## Mode)

inline void init_BGMode() {
    HV *hv = perl_get_hv("QPainter::BGMode", TRUE | GV_ADDMULTI);

    STORE_mode(Transparent);
    STORE_mode(Opaque);
}

MODULE = QPainter		PACKAGE = QPainter

PROTOTYPES: ENABLE

BOOT:
    init_BGMode();

PPainter *
PPainter::new()

PColor *
QPainter::backgroundColor()
    CODE:
    RETVAL = new PColor(THIS->backgroundColor());
    OUTPUT:
    RETVAL

BGMode
QPainter::backgroundMode()

bool
QPainter::begin(paintdevice)
    QPaintDevice *paintdevice

PRect *
QPainter::boundingRect(...)
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int flags = SvIV(ST(5));
	char *str = SvPV(ST(6), na);
	int len = (items > 7) ? SvIV(ST(7)) : -1;
	CODE:
	RETVAL = new PRect(THIS->boundingRect(x, y, w, h, flags, str, len));
	OUTPUT:
	RETVAL
    CASE: items > 3
	PREINIT:
	QRect *rect = pextract(QRect, 1);
	int flags = SvIV(ST(2));
	char *str = SvPV(ST(3), na);
	int len = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	RETVAL = new PRect(THIS->boundingRect(*rect, flags, str, len));
	OUTPUT:
	RETVAL


PPoint *
QPainter::brushOrigin()
    CODE:
    RETVAL = new PPoint(THIS->brushOrigin());
    OUTPUT:
    RETVAL

PRegion *
QPainter::clipRegion()
    CODE:
    RETVAL = new PRegion(THIS->clipRegion());
    OUTPUT:
    RETVAL

QPaintDevice *
QPainter::device()

void
QPainter::drawArc(...)
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int a = SvIV(ST(5));
	int alen = SvIV(ST(6));
	CODE:
	THIS->drawArc(x, y, w, h, a, alen);
    CASE: items > 3
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	int a = SvIV(ST(2));
	int alen = SvIV(ST(3));
	CODE:
	THIS->drawArc(*rect, a, alen);

void
QPainter::drawChord(...)
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int a = SvIV(ST(5));
	int alen = SvIV(ST(6));
	CODE:
	THIS->drawChord(x, y, w, h, a, alen);
    CASE: items > 3
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	int a = SvIV(ST(2));
	int alen = SvIV(ST(3));
	CODE:
	THIS->drawChord(*rect, a, alen);

void
QPainter::drawEllipse(...)
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->drawEllipse(x, y, w, h);
    CASE: items > 1
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->drawEllipse(*rect);

void
QPainter::drawLine(arg1, arg2, ...)
    CASE: items == 3
	PREINIT:
	QPoint *p1 = (QPoint *)extract_ptr(ST(1), "QPoint");
	QPoint *p2 = (QPoint *)extract_ptr(ST(2), "QPoint");
	CODE:
	THIS->drawLine(*p1, *p2);
    CASE: items > 4
	PREINIT:
	int x1 = SvIV(ST(1));
	int y1 = SvIV(ST(2));
	int x2 = SvIV(ST(3));
	int y2 = SvIV(ST(4));
	CODE:
	THIS->drawLine(x1, y1, x2, y2);

void
QPainter::drawLineSegments(parray, index = 0, nlines = -1)
    QPointArray *parray
    int index
    int nlines
    CODE:
    THIS->drawLineSegments(*parray, index, nlines);

void
QPainter::drawPie(...)
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int a = SvIV(ST(5));
	int alen = SvIV(ST(6));
	CODE:
	THIS->drawPie(x, y, w, h, a, alen);
    CASE: items > 3
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	int a = SvIV(ST(2));
	int alen = SvIV(ST(3));
	CODE:
	THIS->drawPie(*rect, a, alen);

void
QPainter::drawPixmap(...)
    CASE: !sv_isobject(ST(1)) && items > 3
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	QPixmap *pix = (QPixmap *)extract_ptr(ST(3), "QPixmap");
	int sx = (items > 4) ? SvIV(ST(4)) : 0;
	int sy = (items > 5) ? SvIV(ST(5)) : 0;
	int sw = (items > 6) ? SvIV(ST(6)) : -1;
	int sh = (items > 7) ? SvIV(ST(7)) : -1;
	CODE:
	THIS->drawPixmap(x, y, *pix, sx, sy, sw, sh);
    CASE: items > 3
	PREINIT:
	QPoint *p = (QPoint *)extract_ptr(ST(1), "QPoint");
	QPixmap *pix = (QPixmap *)extract_ptr(ST(2), "QPixmap");
	QRect *sr = (QRect *)extract_ptr(ST(3), "QRect");
	CODE:
	THIS->drawPixmap(*p, *pix, *sr);
    CASE: items == 3
	PREINIT:
	QPoint *p = (QPoint *)extract_ptr(ST(1), "QPoint");
	QPixmap *pix = (QPixmap *)extract_ptr(ST(2), "QPixmap");
	CODE:
	THIS->drawPixmap(*p, *pix);
    CASE:
	CODE:
	croak("Usage: $painter->drawPixmap(x, y, pixmap, sx = 0, sy = 0, sw = -1, sh = -1);\nUsage: $painter->drawPixmap(point, pixmap, rect);\nUsage: $painter->drawPixmap(point, pixmap);"); 

void
QPainter::drawPoint(arg1, ...)
    CASE: items == 2
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	THIS->drawPoint(*point);
    CASE: items > 2
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	CODE:
	THIS->drawPoint(x, y);

void
QPainter::drawPolygon(parray, winding = FALSE, index = 0, nlines = -1)
    QPointArray *parray
    bool winding
    int index
    int nlines
    CODE:
    THIS->drawPolygon(*parray, winding, index, nlines);

void
QPainter::drawPolyline(parray, index = 0, npoints = -1)
    QPointArray *parray
    int index
    int npoints
    CODE:
    THIS->drawPolyline(*parray, index, npoints);

void
QPainter::drawQuadBezier(parray, index = 0)
    QPointArray *parray
    int index
    CODE:
    THIS->drawQuadBezier(*parray, index);

void
QPainter::drawRect(...)
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->drawRect(x, y, w, h);
    CASE: items > 1
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->drawRect(*rect);

void
QPainter::drawRoundRect(arg1, arg2, arg3, ...)
    CASE: items == 4
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	int xRnd = SvIV(ST(2));
	int yRnd = SvIV(ST(3));
	CODE:
	THIS->drawRoundRect(*rect, xRnd, yRnd);
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int xRnd = SvIV(ST(5));
	int yRnd = SvIV(ST(6));
	CODE:
	THIS->drawRoundRect(x, y, w, h, xRnd, yRnd);

void
QPainter::drawText(...)
    CASE: items > 6
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	int flags = SvIV(ST(5));
	char *str = SvPV(ST(6), na);
	int len = (items > 7) ? SvIV(ST(7)) : -1;
	QRect *br = (items > 8) ? (QRect *)extract_ptr(ST(8), "QRect") : 0;
	CODE:
	THIS->drawText(x, y, w, h, flags, str, len, br);
    CASE: !sv_isobject(ST(1))
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	char *str = SvPV(ST(3), na);
	int len = (items > 4) ? SvIV(ST(4)) : -1;
	CODE:
	THIS->drawText(x, y, str, len);
    CASE: items > 3 && SvIOK(ST(2))
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	int flags = SvIV(ST(2));
	char *str = SvPV(ST(3), na);
	int len = (items > 4) ? SvIV(ST(4)) : -1;
	QRect *br = (items > 5) ? (QRect *)extract_ptr(ST(5), "QRect") : 0;
	CODE:
	THIS->drawText(*rect, flags, str, len, br);
    CASE: items > 2
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	char *str = SvPV(ST(2), na);
	int len = (items > 3) ? SvIV(ST(3)) : -1;
	CODE:
	THIS->drawText(*point, str, len);
    CASE:
	CODE:
	croak("Usage: $painter->drawText(x, y, str, len = -1);\nUsage: $painter->drawText(point, str, len = -1);\nUsage: $painter->drawText(x, y, w, h, flags, str, len = -1, boundrect = undef);\nUsage: $painter->drawText(rect, flags, str, len = -1, br = undef);");

void
QPainter::drawWinFocusRect(...)
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->drawWinFocusRect(x, y, w, h);
    CASE: items > 1
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->drawWinFocusRect(*rect);

bool
QPainter::end()

void
QPainter::eraseRect(...)
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->eraseRect(x, y, w, h);
    CASE: items > 1
	PREINIT:
	QRect *rect = pextract(QRect, 1);
	CODE:
	THIS->eraseRect(*rect);

void
QPainter::fillRect(...)
    CASE: items > 5
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	QBrush *brush = pextract(QBrush, 1);
	CODE:
	THIS->fillRect(x, y, w, h, *brush);
    CASE: items > 2
	PREINIT:
	QRect *rect = pextract(QRect, 1);
	QBrush *brush = pextract(QBrush, 2);
	CODE:
	THIS->fillRect(*rect, *brush);

PFont *
QPainter::font()
    CODE:
    RETVAL = new PFont(THIS->font());
    OUTPUT:
    RETVAL

PFontInfo *
QPainter::fontInfo()
    CODE:
    RETVAL = new PFontInfo(THIS->fontInfo());
    OUTPUT:
    RETVAL

PFontMetrics *
QPainter::fontMetrics()
    CODE:
    RETVAL = new PFontMetrics(THIS->fontMetrics());
    OUTPUT:
    RETVAL

bool
QPainter::hasClipping()

bool
QPainter::hasViewXForm()

bool
QPainter::hasWorldXForm()

bool
QPainter::isActive()

void
QPainter::lineTo(...)
    CASE: items > 2
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	CODE:
	THIS->lineTo(x, y);
    CASE: items > 1
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	THIS->lineTo(*point);

void
QPainter::moveTo(...)
    CASE: items > 2
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	CODE:
	THIS->moveTo(x, y);
    CASE: items > 1
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	THIS->moveTo(*point);

PPen *
QPainter::pen()
    CODE:
    RETVAL = new PPen(THIS->pen());
    OUTPUT:
    RETVAL

RasterOp
QPainter::rasterOp()

void
QPainter::resetXForm()

void
QPainter::restore()

void
QPainter::rotate(a)
    float a

void
QPainter::save()

void
QPainter::scale(sx, sy)
    float sx
    float sy

void
QPainter::setBackgroundColor(color)
    QColor *color
    CODE:
    THIS->setBackgroundColor(*color);

void
QPainter::setBackgroundMode(mode)
    BGMode mode

void
QPainter::setBrush(brush)
    CASE: !sv_isobject(ST(1))
	BrushStyle brush
    CASE: sv_derived_from(ST(1), "QBrush")
	QBrush *brush
	CODE:
	THIS->setBrush(*brush);
    CASE: sv_derived_from(ST(1), "QColor")
	QColor *brush
	CODE:
	THIS->setBrush(*brush);

void
QPainter::setBrushOrigin(arg1, ...)
    CASE: items == 2
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	THIS->setBrushOrigin(*point);
    CASE:
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	CODE:
	THIS->setBrushOrigin(x, y);

void
QPainter::setClipping(b)
    bool b

void
QPainter::setClipRect(arg1, ...)
    CASE: items == 2
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->setClipRect(*rect);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->setClipRect(x, y, w, h);

void
QPainter::setClipRegion(region)
    QRegion *region
    CODE:
    THIS->setClipRegion(*region);

void
QPainter::setFont(font)
    QFont *font
    CODE:
    THIS->setFont(*font);

void
QPainter::setPen(pen)
    CASE: !sv_isobject(ST(1))
	PenStyle pen
    CASE: sv_derived_from(ST(1), "QPen")
	QPen *pen
	CODE:
	THIS->setPen(*pen);
    CASE: sv_derived_from(ST(1), "QColor")
	QColor *pen
	CODE:
	THIS->setPen(*pen);

void
QPainter::setRasterOp(op)
    RasterOp op
    CODE:
    THIS->setRasterOp(op);

void
QPainter::setViewXForm(b)
    bool b

void
QPainter::setViewport(arg1, ...)
    CASE: items == 2
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->setViewport(*rect);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->setViewport(x, y, w, h);

void
QPainter::setWindow(arg1, ...)
    CASE: items == 2
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->setWindow(*rect);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->setWindow(x, y, w, h);

void
QPainter::setWorldMatrix(matrix, concat = FALSE)
    QWMatrix *matrix
    bool concat
    CODE:
    THIS->setWorldMatrix(*matrix, concat);

void
QPainter::setWorldXForm(b)
    bool b

void
QPainter::shear(sh, sv)
    float sh
    float sv

void
QPainter::translate(dx, dy)
    float dx
    float dy

PRect *
QPainter::viewport()
    CODE:
    RETVAL = new PRect(THIS->viewport());
    OUTPUT:
    RETVAL

PRect *
QPainter::window()
    CODE:
    RETVAL = new PRect(THIS->window());
    OUTPUT:
    RETVAL

PWMatrix *
QPainter::worldMatrix()
    CODE:
    RETVAL = new PWMatrix(THIS->worldMatrix());
    OUTPUT:
    RETVAL

SV *
QPainter::xForm(place)
    CASE: sv_derived_from(ST(1), "QPoint")
	QPoint *place
	CODE:
	RETVAL = objectify_ptr(new PPoint(THIS->xForm(*place)), "QPoint", 1);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QRect")
	QRect *place
	CODE:
	RETVAL = objectify_ptr(new PRect(THIS->xForm(*place)), "QRect", 1);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QPointArray")
	QPointArray *place
	CODE:
	RETVAL = objectify_ptr(new QPointArray(THIS->xForm(*place)),
			       "QPointArray", 1);
	OUTPUT:
	RETVAL

SV *
QPainter::xFormDev(place)
    CASE: sv_derived_from(ST(1), "QPoint")
	QPoint *place
	CODE:
	RETVAL =
	    objectify_ptr(new PPoint(THIS->xFormDev(*place)), "QPoint", 1);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QRect")
	QRect *place
	CODE:
	RETVAL = objectify_ptr(new PRect(THIS->xFormDev(*place)), "QRect", 1);
	OUTPUT:
	RETVAL
    CASE: sv_derived_from(ST(1), "QPointArray")
	QPointArray *place
	CODE:
	RETVAL = objectify_ptr(new QPointArray(THIS->xFormDev(*place)),
			       "QPointArray", 1);
	OUTPUT:
	RETVAL
