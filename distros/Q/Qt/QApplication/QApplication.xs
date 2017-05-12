/*
 * PerlQt interface to qapp.h
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "papp.h"

MODULE = QApplication		PACKAGE = QApplication		

PROTOTYPES: ENABLE

PApplication *
PApplication::new()
    PREINIT:
    int argc = 0;
    char **argv = NULL;
    CODE:
    AV *ARGV = perl_get_av("ARGV", FALSE);
    SV *ARGV0 = perl_get_sv("0", FALSE);

    New(123, argv, argc+1, char *);  // allocate sizeof(char *) for argv
    argc = 0;
    argv[0] = NULL;                  // initialization is good
    if(ARGV0) {
	STRLEN ARGV0_len;
	char *ARGV0_str = SvPV(ARGV0, ARGV0_len);  // Gimmie the script name
	Renew(argv, ++argc+1, char *);             // Extend argv
	if(ARGV0_str) {                            // paranoia is good
	    New(123, argv[argc-1], ARGV0_len+1, char);
	    Copy(ARGV0_str, argv[argc-1], ARGV0_len+1, char);
	    argv[argc] = NULL;
	} else {                                   // Extreme paranoia
	    warn("Unable to retrieve $0, that's impossible");
	    New(123, argv[argc-1], 1, char);
	    *argv[argc-1] = '\0';
	}
	if(ARGV)
	    for(I32 elem = 0; elem <= av_len(ARGV); elem++) {
		SV **ARGV_sv = av_fetch(ARGV, elem, 0);
		STRLEN ARGV_elem_len;
		char *ARGV_elem;

		if(!ARGV_sv) continue;
		ARGV_elem = SvPV(*ARGV_sv, ARGV_elem_len);
		Renew(argv, ++argc+1, char *);
		New(123, argv[argc-1], ARGV_elem_len+1, char);
		Copy(ARGV_elem, argv[argc-1], ARGV_elem_len+1, char);
		argv[argc-1][ARGV_elem_len] = '\0';  // paranoia is good
	    }
    }

    RETVAL = new PApplication(argc, argv);  // The memory in argv is leaked :(
    argc = RETVAL->argc();
    argv = RETVAL->argv();
    av_clear(ARGV);                          // Free the command-line args...
    if(argc) { sv_setpv(ARGV0, argv[0]); argc--; argv++; }
    for(int i = 0; i < argc; i++)
	av_push(ARGV, newSVpv(argv[i], 0));  // rebuild @ARGV
    OUTPUT:
    RETVAL

void
beep()
    CODE:
    QApplication::beep();

QClipboard *
clipboard()
    CODE:
    RETVAL = QApplication::clipboard();
    OUTPUT:
    RETVAL

bool
closingDown()
    CODE:
    RETVAL = QApplication::closingDown();
    OUTPUT:
    RETVAL

QApplication::ColorMode
colorMode()
    CODE:
    RETVAL = QApplication::colorMode();
    OUTPUT:
    RETVAL

QWidget *
desktop()
    CODE:
    RETVAL = QApplication::desktop();
    OUTPUT:
    RETVAL

int
QApplication::enter_loop()

int
QApplication::exec()

void
exit(retcode = 0)
    int retcode
    CODE:
    QApplication::exit(retcode);

void
QApplication::exit_loop()

void
flushX()
    CODE:
    QApplication::flushX();

QWidget *
QApplication::focusWidget()

QFont *
font()
    CODE:
    RETVAL = QApplication::font();
    OUTPUT:
    RETVAL

PFontMetrics *
fontMetrics()
    CODE:
    RETVAL = new PFontMetrics(QApplication::fontMetrics());
    OUTPUT:
    RETVAL

QWidget *
QApplication::mainWidget()

bool
QApplication::notify(receiver, event)
    QObject *receiver
    QEvent *event

QCursor *
overrideCursor()
    CODE:
    RETVAL = QApplication::overrideCursor();
    OUTPUT:
    RETVAL

QPalette *
palette()
    CODE:
    RETVAL = QApplication::palette();
    OUTPUT:
    RETVAL

void
postEvent(receiver, event)
    QObject *receiver
    QEvent *event
    CODE:
    QApplication::postEvent(receiver, event);

void
QApplication::processEvents()

void
QApplication::quit()

void
restoreOverrideCursor()
    CODE:
    QApplication::restoreOverrideCursor();

bool
sendEvent(receiver, event)
    QObject *receiver
    QEvent *event
    CODE:
    RETVAL = QApplication::sendEvent(receiver, event);
    OUTPUT:
    RETVAL

void
setColorMode(mode)
    QApplication::ColorMode mode
    CODE:
    QApplication::setColorMode(mode);

void
setFont(font, updateAllWidgets = FALSE)
    QFont *font
    bool updateAllWidgets
    CODE:
    QApplication::setFont(*font, updateAllWidgets);

void
QApplication::setMainWidget(widget)
    QWidget *widget

void
setOverrideCursor(cursor, replace = FALSE)
    QCursor *cursor
    bool replace
    CODE:
    QApplication::setOverrideCursor(*cursor, replace);

void
setPalette(palette, updateAllWidgets = FALSE)
    QPalette *palette
    bool updateAllWidgets
    CODE:
    QApplication::setPalette(*palette, updateAllWidgets);

void
setStyle(style)
    GUIStyle style
    CODE:
    QApplication::setStyle(style);

bool
startingUp()
    CODE:
    RETVAL = QApplication::startingUp();
    OUTPUT:
    RETVAL

GUIStyle
style()
    CODE:
    RETVAL = QApplication::style();
    OUTPUT:
    RETVAL

void
syncX()
    CODE:
    QApplication::syncX();

QWidget *
widgetAt(arg1, ...)
    CASE: sv_isobject(ST(0))
	PREINIT:
	QPoint *point = pextract(QPoint, 0);
	bool child = (items > 1) ? (SvIV(ST(1)) ? TRUE : FALSE) : FALSE;
	CODE:
	RETVAL = QApplication::widgetAt(*point, child);
	OUTPUT:
	RETVAL
    CASE: items > 1
	PREINIT:
	int x = SvIV(ST(0));
	int y = SvIV(ST(1));
	bool child = (items > 2) ? (SvIV(ST(2)) ? TRUE : FALSE) : FALSE;
	CODE:
	RETVAL = QApplication::widgetAt(x, y, child);
	OUTPUT:
	RETVAL
