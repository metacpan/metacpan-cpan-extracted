TEMPLATE = app
CONFIG += console c++11
CONFIG -= app_bundle
CONFIG -= qt

INCLUDEPATH += src ../CPP-panda-lib/src  ../CPP-catch/src  ../URI-XS/src ../UniEvent/src  ../UniEvent/libuv/include ../Protocol-HTTP/src

SOURCES += \
    src/panda/protocol/websocket/ClientParser.cc \
    src/panda/protocol/websocket/ConnectRequest.cc \
    src/panda/protocol/websocket/ConnectResponse.cc \
    src/panda/protocol/websocket/DeflateExt.cc \
    src/panda/protocol/websocket/Frame.cc \
    src/panda/protocol/websocket/FrameBuilder.cc \
    src/panda/protocol/websocket/FrameHeader.cc \
    src/panda/protocol/websocket/HTTPPacket.cc \
    src/panda/protocol/websocket/HTTPRequest.cc \
    src/panda/protocol/websocket/HTTPResponse.cc \
    src/panda/protocol/websocket/Message.cc \
    src/panda/protocol/websocket/Parser.cc \
    src/panda/protocol/websocket/ServerParser.cc \
    src/panda/protocol/websocket/utils.cc \
    src/xs/protocol/websocket.cc \
    XS.cc \
    src/panda/protocol/http/HeaderValueParamsParser.cc \
    src/panda/protocol/websocket/Error.cc

DISTFILES += \
    t/99-leaks.t \
    t/ClientParser-connect.t \
    t/ClientParser-connect_request.t \
    t/Extension-Deflate-selection.t \
    t/FrameBuilder.t \
    t/MyTest.pm \
    t/Parser-deflate-frames.t \
    t/Parser-get-mixed-mode.t \
    t/Parser-get_frames.t \
    t/Parser-get_messages.t \
    t/Parser-inflate-frames.t \
    t/Parser-send_control.t \
    t/Parser-send_frame.t \
    t/Parser-send_message.t \
    t/ServerParser-accept.t \
    t/ServerParser-accept_error.t \
    t/ServerParser-accept_response.t \
    ClientParser.xsi \
    ConnectRequest.xsi \
    ConnectResponse.xsi \
    Frame.xsi \
    FrameBuilder.xsi \
    FrameIterator.xsi \
    HTTPPacket.xsi \
    HTTPRequest.xsi \
    HTTPResponse.xsi \
    Message.xsi \
    MessageIterator.xsi \
    Parser.xsi \
    ServerParser.xsi \
    Error.xsi \
    lib/Protocol/WebSocket/XS/errc.pm

HEADERS += \
    src/panda/protocol/websocket/ClientParser.h \
    src/panda/protocol/websocket/ConnectRequest.h \
    src/panda/protocol/websocket/ConnectResponse.h \
    src/panda/protocol/websocket/DeflateExt.h \
    src/panda/protocol/websocket/Frame.h \
    src/panda/protocol/websocket/FrameBuilder.h \
    src/panda/protocol/websocket/FrameHeader.h \
    src/panda/protocol/websocket/HTTPPacket.h \
    src/panda/protocol/websocket/HTTPRequest.h \
    src/panda/protocol/websocket/HTTPResponse.h \
    src/panda/protocol/websocket/inc.h \
    src/panda/protocol/websocket/iterator.h \
    src/panda/protocol/websocket/Message.h \
    src/panda/protocol/websocket/Parser.h \
    src/panda/protocol/websocket/ParserError.h \
    src/panda/protocol/websocket/ServerParser.h \
    src/panda/protocol/websocket/utils.h \
    src/panda/protocol/websocket.h \
    src/panda/ranges/Joiner.h \
    src/panda/ranges/KmpFinder.h \
    src/xs/protocol/websocket.h \
    src/panda/protocol/http/HeaderValueParamsParser.h \
    src/panda/protocol/websocket/Error.h
