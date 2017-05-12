MODULE = Search::Xapian	 PACKAGE = Search::Xapian::AssertionError

PROTOTYPES: ENABLE

string
AssertionError::get_type()

string
AssertionError::get_msg()

string
AssertionError::get_context()

const char *
AssertionError::get_error_string()

void
AssertionError::DESTROY()
