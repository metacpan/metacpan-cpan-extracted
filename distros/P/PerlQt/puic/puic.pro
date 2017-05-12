
TEMPLATE = app
INCLUDEPATH += .

CONFIG += qt warn_on

exists( $(QTDIR)/lib/libqt-mt* ) {
      CONFIG += thread
}

DEFINES += UIC QT_INTERNAL_XML

# Input
HEADERS += domtool.h \
           globaldefs.h \
           parser.h \
           uic.h \
           widgetdatabase.h \
           widgetinterface.h
SOURCES += domtool.cpp \
           embed.cpp \
           form.cpp \
           main.cpp \
           object.cpp \
           parser.cpp \
           subclassing.cpp \
           uic.cpp \
           widgetdatabase.cpp
