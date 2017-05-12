MODULE = Search::Xapian	 PACKAGE = Search::Xapian::RuntimeError

PROTOTYPES: ENABLE

string
RuntimeError::get_type()

string
RuntimeError::get_msg()

string
RuntimeError::get_context()

const char *
RuntimeError::get_error_string()

void
RuntimeError::DESTROY()

INCLUDE: XS/DatabaseError.xs
INCLUDE: XS/DocNotFoundError.xs
INCLUDE: XS/FeatureUnavailableError.xs
INCLUDE: XS/InternalError.xs
INCLUDE: XS/NetworkError.xs
INCLUDE: XS/QueryParserError.xs
INCLUDE: XS/SerialisationError.xs
INCLUDE: XS/RangeError.xs
