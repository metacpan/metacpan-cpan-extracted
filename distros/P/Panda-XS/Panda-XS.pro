TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
    src/xs/xs.cc

HEADERS += \
    src/xs/ppport.h \
    src/xs/xs-private.h \
    src/xs/xs.h \
    t/src/backref.h \
    t/src/mixin.h \
    t/src/mybase.h \
    t/src/myother.h \
    t/src/myrefcounted.h \
    t/src/mystatic.h \
    t/src/mythreads.h \
    t/src/orefs.h \
    t/src/test.h \
    t/src/wrap.h \
    src/xs/XSCallbackDispatcher.h

DISTFILES += \
    Makefile.PL \
    typemap \
    XS.xs \
    XSCallbackDispatcher.xsi
