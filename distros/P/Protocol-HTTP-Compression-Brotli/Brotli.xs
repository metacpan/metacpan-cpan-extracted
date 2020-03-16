#include <xs.h>
#include <panda/protocol/http/compression/Brotli.h>

using namespace xs;
using namespace panda::protocol::http;


MODULE = Protocol::HTTP::Compression::Brotli    PACKAGE = Protocol::HTTP::Compression::Brotli
PROTOTYPES: DISABLE

BOOT {
        compression::Brotli::register_factory();
}
