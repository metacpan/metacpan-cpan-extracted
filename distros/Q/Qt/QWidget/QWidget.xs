/*
 * PerlQt interface to qwidget.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pfontmet.h"
#include "pwidget.h"
#include "enum.h"

#define STORE_key(key) enumIV(hv, MSTR(key), QWidget::key ## Focus)

inline void init_enum() {
    HV *hv = perl_get_hv("QWidget::FocusPolicy", TRUE | GV_ADDMULTI);

    STORE_key(No);
    STORE_key(Tab);
    STORE_key(Click);
    STORE_key(Strong);
}

#define STORE_state(key) enumIV(hv, MSTR(key), WState_ ## key)
#define STORE_type(key) enumIV(hv, MSTR(key), WType_ ## key)
#define STORE_style(key) enumIV(hv, MSTR(key), WStyle_ ## key)
#define STORE_flag(key) enumIV(hv, MSTR(key), W ## key)

inline void init_WFlags() {
    HV *hv;
    HV *wflags = perl_get_hv("QWidget::WFlags", TRUE | GV_ADDMULTI);
    HV *state = newHV();
    HV *type = newHV();
    HV *style = newHV();

    safe_hv_store(wflags, "State", newRV_noinc((SV *)state));
    safe_hv_store(wflags, "Type", newRV_noinc((SV *)type));
    safe_hv_store(wflags, "Style", newRV_noinc((SV *)style));

    hv = state;
    STORE_state(Created);
    STORE_state(Disabled);
    STORE_state(Visible);
    STORE_state(DoHide);
    STORE_state(ClickToFocus);
    STORE_state(TrackMouse);
    STORE_state(BlockUpdates);
    STORE_state(PaintEvent);
    STORE_state(TabToFocus);

    hv = type;
    STORE_type(TopLevel);
    STORE_type(Modal);
    STORE_type(Popup);
    STORE_type(Desktop);

    hv = style;
    STORE_style(Customize);
    STORE_style(NormalBorder);
    STORE_style(DialogBorder);
    STORE_style(NoBorder);
    STORE_style(Title);
    STORE_style(SysMenu);
    STORE_style(Minimize);
    STORE_style(Maximize);
    STORE_style(MinMax);
    STORE_style(Tool);
    STORE_style(Mask);

    hv = wflags;
    STORE_flag(CursorSet);
    STORE_flag(DestructiveClose);
    STORE_flag(PaintDesktop);
    STORE_flag(PaintUnclipped);
    STORE_flag(PaintClever);
    STORE_flag(ConfigPending);
    STORE_flag(ResizeNoErase);
    STORE_flag(Recreated);
    STORE_flag(ExportFontMetrics);
    STORE_flag(ExportFontInfo);
    STORE_flag(FocusSet);
}

MODULE = QWidget	PACKAGE = QWidget

PROTOTYPES: ENABLE

BOOT:
    init_enum();
    init_WFlags();

PWidget *
PWidget::new(parent = 0, name = 0, f = 0)
    QWidget *parent
    char *name
    WFlags f

void
QWidget::adjustSize()

PColor *
QWidget::backgroundColor()
    CODE:
    RETVAL = new PColor(THIS->backgroundColor());
    OUTPUT:
    RETVAL

PPixmap *
QWidget::backgroundPixmap()
    CODE:
    RETVAL = new PPixmap(*(THIS->backgroundPixmap()));
    OUTPUT:
    RETVAL

const char *
QWidget::caption()

PRect *
QWidget::childrenRect()
    CODE:
    RETVAL = new PRect(THIS->childrenRect());
    OUTPUT:
    RETVAL

void
QWidget::clearFocus()

void
QWidget::close(forceKill = FALSE)
    bool forceKill

void
QWidget::drawText(...)
    CASE: items > 3
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	char *str = SvPV(ST(3), na);
	CODE:
	THIS->drawText(x, y, str);
    CASE:
	CODE:
	croak("Usage: $widget->drawText(x, y, text);");
	
void
QWidget::erase(...)
    CASE: items == 1
	CODE:
	THIS->erase();
    CASE: items == 2
	PREINIT:
	QRect *r = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->erase(*r);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->erase(x, y, w, h);
    CASE:
	CODE:
	croak("Usage: $widget->erase(x, y, w, h);\nUsage: $widget->erase(rect);\nUsage: $widget->erase();");

QWidget::FocusPolicy
QWidget::focusPolicy()

PFont *
QWidget::font()
    CODE:
    RETVAL = new PFont(THIS->font());
    OUTPUT:
    RETVAL

PFontMetrics *
QWidget::fontMetrics()
    CODE:
    RETVAL = new PFontMetrics(THIS->fontMetrics());
    OUTPUT:
    RETVAL

PColor *
QWidget::foregroundColor()
    CODE:
    RETVAL = new PColor(THIS->foregroundColor());
    OUTPUT:
    RETVAL

PRect *
QWidget::frameGeometry()
    CODE:
    RETVAL = new PRect(THIS->frameGeometry());
    OUTPUT:
    RETVAL

PRect *
QWidget::geometry()
    CODE:
    RETVAL = new PRect(THIS->geometry());
    OUTPUT:
    RETVAL

void
QWidget::grabKeyboard()

void
QWidget::grabMouse()

bool
QWidget::hasFocus()

bool
QWidget::hasMouseTracking()

int
QWidget::height()

void
QWidget::hide()

PPixmap *
QWidget::icon()
    CODE:
    RETVAL = new PPixmap(*(THIS->icon()));
    OUTPUT:
    RETVAL

const char *
QWidget::iconText()

void
QWidget::iconify()

bool
QWidget::isActiveWindow()

bool
QWidget::isDesktop()

bool
QWidget::isEnabled()

bool
QWidget::isFocusEnabled()

bool
QWidget::isModal()

bool
QWidget::isPopup()

bool
QWidget::isTopLevel()

bool
QWidget::isUpdatesEnabled()

bool
QWidget::isVisible()

QWidget *
keyboardGrabber()
    CODE:
    RETVAL = QWidget::keyboardGrabber();
    OUTPUT:
    RETVAL

void
QWidget::lower()

PPoint *
QWidget::mapFromGlobal(point)
    QPoint *point
    CODE:
    RETVAL = new PPoint(THIS->mapFromGlobal(*point));
    OUTPUT:
    RETVAL

PPoint *
QWidget::mapFromParent(point)
    QPoint *point
    CODE:
    RETVAL = new PPoint(THIS->mapFromParent(*point));
    OUTPUT:
    RETVAL

PPoint *
QWidget::mapToGlobal(point)
    QPoint *point
    CODE:
    RETVAL = new PPoint(THIS->mapToGlobal(*point));
    OUTPUT:
    RETVAL

PPoint *
QWidget::mapToParent(point)
    QPoint *point
    CODE:
    RETVAL = new PPoint(THIS->mapToParent(*point));
    OUTPUT:
    RETVAL

PSize *
QWidget::maximumSize()
    CODE:
    RETVAL = new PSize(THIS->maximumSize());
    OUTPUT:
    RETVAL

PSize *
QWidget::minimumSize()
    CODE:
    RETVAL = new PSize(THIS->minimumSize());
    OUTPUT:
    RETVAL

QWidget *
mouseGrabber()
    CODE:
    RETVAL = QWidget::mouseGrabber();
    OUTPUT:
    RETVAL

void
QWidget::move(...)
    CASE: items == 2
	PREINIT:
	QPoint *point = (QPoint *)extract_ptr(ST(1), "QPoint");
	CODE:
	THIS->move(*point);
    CASE: items > 2
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	CODE:
	THIS->move(x, y);

PPoint *
QWidget::pos()
    CODE:
    RETVAL = new PPoint(THIS->pos());
    OUTPUT:
    RETVAL

void
QWidget::raise()

void
QWidget::recreate(parent, flags, point, showIt = FALSE)
    QWidget *parent
    WFlags flags
    QPoint *point
    bool showIt
    CODE:
    THIS->recreate(parent, flags, *point, showIt);

PRect *
QWidget::rect()
    CODE:
    RETVAL = new PRect(THIS->rect());
    OUTPUT:
    RETVAL

void
QWidget::releaseKeyboard()

void
QWidget::releaseMouse()

void
QWidget::repaint(...)
    CASE: items < 3 && !sv_isobject(ST(1))
	PREINIT:
	bool erase = (items > 1) ? (SvIV(ST(1)) ? TRUE : FALSE) : TRUE;
	CODE:
	THIS->repaint(erase);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	bool erase = (items > 5) ? (SvIV(ST(5)) ? TRUE : FALSE) : TRUE;
	CODE:
	THIS->repaint(x, y, w, h, erase);
    CASE: sv_isobject(ST(1))
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	bool erase = (items > 2) ? (SvTRUE(ST(2)) ? TRUE : FALSE) : TRUE;
	CODE:
	THIS->repaint(*rect, erase);
    CASE:
	CODE:
	croak("Usage: $widget->repaint(erase = 1);\nUsage: $widget->repaint(QRect, erase = 1);\nUsage: $widget->repaint(x, y, w, h, erase = 1);");

void
QWidget::resize(...)
    CASE: items == 2
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	CODE:
	THIS->resize(*size);
    CASE: items > 2
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->resize(w, h);

void
QWidget::scroll(dx, dy)
    int dx
    int dy

void
QWidget::setActiveWindow()

void
QWidget::setBackgroundColor(color)
    QColor *color
    CODE:
    THIS->setBackgroundColor(*color);

void
QWidget::setBackgroundPixmap(pixmap)
    QPixmap *pixmap
    CODE:
    THIS->setBackgroundPixmap(*pixmap);

void
QWidget::setCaption(caption)
    char *caption

void
QWidget::setCursor(cursor)
    QCursor *cursor
    CODE:
    THIS->setCursor(*cursor);

void
QWidget::setEnabled(enabled)
    bool enabled

void
QWidget::setFixedSize(arg1, ...)
    CASE: items == 2
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	CODE:
	THIS->setFixedSize(*size);
    CASE: items > 2
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->setFixedSize(w, h);

void
QWidget::setFocus()

void
QWidget::setFocusPolicy(policy)
    QWidget::FocusPolicy policy

void
QWidget::setFont(font)
    QFont *font
    CODE:
    THIS->setFont(*font);

void
QWidget::setGeometry(x, y, w, h)
    CASE: items == 1
	PREINIT:
	QRect *rect = (QRect *)extract_ptr(ST(1), "QRect");
	CODE:
	THIS->setGeometry(*rect);
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->setGeometry(x, y, w, h);

void
QWidget::setIcon(pixmap)
    QPixmap *pixmap
    CODE:
    THIS->setIcon(*pixmap);

void
QWidget::setIconText(text)
    char *text

void
QWidget::setMaximumSize(arg1, ...)
    CASE: items == 2
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	CODE:
	THIS->setMaximumSize(*size);
    CASE: items > 2
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->setMaximumSize(w, h);

void
QWidget::setMinimumSize(arg1, ...)
    CASE: items == 2
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	CODE:
	THIS->setMinimumSize(*size);
    CASE: items > 2
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->setMinimumSize(w, h);

void
QWidget::setMouseTracking(enable)
    bool enable

void
QWidget::setSizeIncrement(arg1, ...)
    CASE: items == 2
	PREINIT:
	QSize *size = (QSize *)extract_ptr(ST(1), "QSize");
	CODE:
	THIS->setSizeIncrement(*size);
    CASE: items > 2
	PREINIT:
	int w = SvIV(ST(1));
	int h = SvIV(ST(2));
	CODE:
	THIS->setSizeIncrement(w, h);

void
QWidget::setStyle(style)
    GUIStyle style

void
QWidget::setUpdatesEnabled(enable)
    bool enable

void
QWidget::show()

PSize *
QWidget::size()
    CODE:
    RETVAL = new PSize(THIS->size());
    OUTPUT:
    RETVAL

PSize *
QWidget::sizeHint()
    CODE:
    RETVAL = new PSize(THIS->sizeHint());
    OUTPUT:
    RETVAL

PSize *
QWidget::sizeIncrement()
    CODE:
    RETVAL = new PSize(THIS->sizeIncrement());
    OUTPUT:
    RETVAL

GUIStyle
QWidget::style()

QWidget *
QWidget::topLevelWidget()

void
QWidget::update(...)
    CASE: items == 1
	CODE:
	THIS->update();
    CASE: items > 4
	PREINIT:
	int x = SvIV(ST(1));
	int y = SvIV(ST(2));
	int w = SvIV(ST(3));
	int h = SvIV(ST(4));
	CODE:
	THIS->update(x, y, w, h);

int
QWidget::width()

IV
QWidget::winId()

int
QWidget::x()

int
QWidget::y()

MODULE = QWidget	PACKAGE = QWidget	PREFIX = protected_

void
pWidget::protected_mouseMoveEvent(event)
    QMouseEvent *event

void
pWidget::protected_mousePressEvent(event)
    QMouseEvent *event

void
pWidget::protected_mouseReleaseEvent(event)
    QMouseEvent *event

void
pWidget::protected_paintEvent(event)
    QPaintEvent *event

void
pWidget::protected_resizeEvent(event)
    QResizeEvent *event