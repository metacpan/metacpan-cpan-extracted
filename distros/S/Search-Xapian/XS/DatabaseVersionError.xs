MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseVersionError

PROTOTYPES: ENABLE

string
DatabaseVersionError::get_type()

string
DatabaseVersionError::get_msg()

string
DatabaseVersionError::get_context()

const char *
DatabaseVersionError::get_error_string()

void
DatabaseVersionError::DESTROY()
