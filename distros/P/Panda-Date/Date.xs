#include "Date.h"
#include "util.h"

using namespace xs::date;
using namespace panda::time;
using namespace panda::date;
using panda::string;

MODULE = Panda::Date                PACKAGE = Panda::Date
PROTOTYPES: DISABLE

INCLUDE: Date.xsi
INCLUDE: DateRel.xsi
INCLUDE: DateInt.xsi
INCLUDE: serialize.xsi
