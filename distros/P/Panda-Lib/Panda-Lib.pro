TEMPLATE = lib
CONFIG += console
CONFIG -= app_bundle
CONFIG -= qt

HEADERS += \
    src/panda/iterator.h \
    src/panda/lib.h \
    src/panda/string.h \
    src/panda/lib/def.h \
    src/panda/lib/lib.h \
    src/panda/lib/memory.h

SOURCES += \
    src/panda/lib/lib.cc \
    src/panda/lib/memory.cc

INCLUDEPATH += src

