MODULE = Search::Xapian	 PACKAGE = Search::Xapian::WildcardError

PROTOTYPES: ENABLE

string
WildcardError::get_type()

string
WildcardError::get_msg()

string
WildcardError::get_context()

const char *
WildcardError::get_error_string()

void
WildcardError::DESTROY()
