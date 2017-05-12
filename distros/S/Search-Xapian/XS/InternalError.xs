MODULE = Search::Xapian	 PACKAGE = Search::Xapian::InternalError

PROTOTYPES: ENABLE

string
InternalError::get_type()

string
InternalError::get_msg()

string
InternalError::get_context()

const char *
InternalError::get_error_string()

void
InternalError::DESTROY()
