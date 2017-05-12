MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseCorruptError

PROTOTYPES: ENABLE

string
DatabaseCorruptError::get_type()

string
DatabaseCorruptError::get_msg()

string
DatabaseCorruptError::get_context()

const char *
DatabaseCorruptError::get_error_string()

void
DatabaseCorruptError::DESTROY()
