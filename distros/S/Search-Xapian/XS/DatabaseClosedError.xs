MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseClosedError

PROTOTYPES: ENABLE

string
DatabaseClosedError::get_type()

string
DatabaseClosedError::get_msg()

string
DatabaseClosedError::get_context()

const char *
DatabaseClosedError::get_error_string()

void
DatabaseClosedError::DESTROY()
