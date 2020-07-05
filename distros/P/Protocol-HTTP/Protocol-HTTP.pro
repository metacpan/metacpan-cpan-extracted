TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

INCLUDEPATH += src ../CPP-panda-lib/src ../CPP-catch/src  ../URI-XS/src ../CPP-Range/include

SOURCES += \
    src/panda/protocol/http/Body.cc \
    src/panda/protocol/http/Header.cc \
    src/panda/protocol/http/HeaderField.cc \
    src/panda/protocol/http/Message.cc \
    src/panda/protocol/http/Request.cc \
    src/panda/protocol/http/RequestParser.cc \
    src/panda/protocol/http/RequestParserGenerated.cc \
    src/panda/protocol/http/Response.cc \
    src/panda/protocol/http/ResponseParser.cc \
    src/panda/protocol/http/ResponseParserGenerated.cc \
    src/xs/protocol/http.cc \
    HTTP.xs \
    Message.xsi \
    t/bad.cc \
    t/basic.cc \
    t/content-length.cc \
    t/fragmented.cc \
    t/regression.cc \
    t/request.cc \
    t/response.cc \
    t/header.cc


DISTFILES += \
    lib/Protocol/HTTP.pm \
    lib/Protocol/HTTP.pod \
    src/panda/protocol/http/RequestParser.rl \
    src/panda/protocol/http/ResponseParser.rl \
    Makefile.PL \
    Request.xsi \
    Response.xsi \
    t/lib/MyTest.pm \
    t/bad.t \
    t/basic.t \
    t/content-length.t \
    t/fragmented.t \
    t/regression.t \
    t/request.t \
    t/response.t \
    t/lib/MyTest.xs \
    t/regression/1/002.000.txt \
    t/regression/1/002.001.txt \
    t/regression/1/002.002.txt \
    t/regression/1/002.003.txt \
    t/regression/1/002.004.txt \
    t/regression/1/002.005.txt \
    t/regression/1/002.006.txt \
    t/regression/1/002.007.txt \
    t/regression/1/002.008.txt \
    t/regression/1/002.009.txt \
    t/regression/1/002.010.txt \
    t/regression/1/002.011.txt \
    t/regression/1/002.012.txt \
    t/regression/1/002.013.txt \
    t/regression/1/002.014.txt \
    t/regression/1/002.015.txt \
    t/regression/1/002.016.txt \
    t/regression/1/002.017.txt \
    t/regression/1/002.018.txt \
    t/regression/1/002.019.txt \
    t/regression/1/002.020.txt \
    t/regression/1/002.021.txt \
    t/regression/1/002.022.txt \
    t/regression/1/002.023.txt \
    t/regression/1/002.024.txt \
    t/regression/1/002.025.txt \
    t/regression/1/002.026.txt \
    t/regression/1/002.027.txt \
    t/regression/1/002.028.txt \
    t/regression/1/002.029.txt \
    t/regression/1/002.030.txt \
    t/regression/1/002.031.txt \
    t/regression/1/002.032.txt \
    t/regression/1/002.033.txt \
    t/regression/1/002.034.txt \
    t/regression/1/002.035.txt \
    t/regression/1/002.036.txt


HEADERS += \
    src/panda/protocol/http/Body.h \
    src/panda/protocol/http/Defines.h \
    src/panda/protocol/http/Header.h \
    src/panda/protocol/http/HeaderField.h \
    src/panda/protocol/http/Message.h \
    src/panda/protocol/http/MessageIterator.h \
    src/panda/protocol/http/MessageParser.h \
    src/panda/protocol/http/ParserError.h \
    src/panda/protocol/http/Request.h \
    src/panda/protocol/http/RequestParser.h \
    src/panda/protocol/http/Response.h \
    src/panda/protocol/http/ResponseParser.h \
    src/xs/protocol/http.h \
    t/lib/test.h \
    src/xs/protocol/http.h \
    t/lib/test.h
