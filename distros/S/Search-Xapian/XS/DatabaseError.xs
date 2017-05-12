MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseError

PROTOTYPES: ENABLE

string
DatabaseError::get_type()

string
DatabaseError::get_msg()

string
DatabaseError::get_context()

const char *
DatabaseError::get_error_string()

void
DatabaseError::DESTROY()

INCLUDE: XS/DatabaseCorruptError.xs
INCLUDE: XS/DatabaseCreateError.xs
INCLUDE: XS/DatabaseLockError.xs
INCLUDE: XS/DatabaseModifiedError.xs
INCLUDE: XS/DatabaseOpeningError.xs
