MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseCreateError

PROTOTYPES: ENABLE

string
DatabaseCreateError::get_type()

string
DatabaseCreateError::get_msg()

string
DatabaseCreateError::get_context()

const char *
DatabaseCreateError::get_error_string()

void
DatabaseCreateError::DESTROY()
