MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseOpeningError

PROTOTYPES: ENABLE

string
DatabaseOpeningError::get_type()

string
DatabaseOpeningError::get_msg()

string
DatabaseOpeningError::get_context()

const char *
DatabaseOpeningError::get_error_string()

void
DatabaseOpeningError::DESTROY()

INCLUDE: XS/DatabaseVersionError.xs
