MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DocNotFoundError

PROTOTYPES: ENABLE

string
DocNotFoundError::get_type()

string
DocNotFoundError::get_msg()

string
DocNotFoundError::get_context()

const char *
DocNotFoundError::get_error_string()

void
DocNotFoundError::DESTROY()
