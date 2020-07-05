#include <xs/export.h>
#include <xs/protocol/http.h>

using namespace xs;
using namespace xs::protocol::http;
using panda::string;
using panda::string_view;
using Date = panda::date::Date;

MODULE = Protocol::HTTP                PACKAGE = Protocol::HTTP
PROTOTYPES: DISABLE

INCLUDE: xsi/Compression.xsi

INCLUDE: xsi/CookieJar.xsi

INCLUDE: xsi/Error.xsi

INCLUDE: xsi/Message.xsi

INCLUDE: xsi/Request.xsi

INCLUDE: xsi/RequestParser.xsi

INCLUDE: xsi/Response.xsi

INCLUDE: xsi/ResponseParser.xsi
