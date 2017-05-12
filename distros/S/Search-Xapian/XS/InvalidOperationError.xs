MODULE = Search::Xapian	 PACKAGE = Search::Xapian::InvalidOperationError

PROTOTYPES: ENABLE

string
InvalidOperationError::get_type()

string
InvalidOperationError::get_msg()

string
InvalidOperationError::get_context()

const char *
InvalidOperationError::get_error_string()

void
InvalidOperationError::DESTROY()
