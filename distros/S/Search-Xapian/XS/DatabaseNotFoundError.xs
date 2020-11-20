MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseNotFoundError

PROTOTYPES: ENABLE

string
DatabaseNotFoundError::get_type()

string
DatabaseNotFoundError::get_msg()

string
DatabaseNotFoundError::get_context()

const char *
DatabaseNotFoundError::get_error_string()

void
DatabaseNotFoundError::DESTROY()
