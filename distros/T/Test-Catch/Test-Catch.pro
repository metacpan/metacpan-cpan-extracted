TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

SOURCES += \
    t/test.cc

DISTFILES += \
    t/run.t \
    Catch.xs
