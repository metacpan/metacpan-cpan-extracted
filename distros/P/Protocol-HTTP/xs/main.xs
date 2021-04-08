#include <xs/export.h>
#include <xs/protocol/http.h>

using namespace xs;
using namespace xs::protocol::http;
using panda::string;
using panda::string_view;
using Date = panda::date::Date;

MODULE = Protocol::HTTP                PACKAGE = Protocol::HTTP
PROTOTYPES: DISABLE

INCLUDE: Compression.xsi

INCLUDE: CookieJar.xsi

INCLUDE: Error.xsi

INCLUDE: Message.xsi

INCLUDE: Request.xsi

INCLUDE: RequestParser.xsi

INCLUDE: Response.xsi

INCLUDE: ResponseParser.xsi
