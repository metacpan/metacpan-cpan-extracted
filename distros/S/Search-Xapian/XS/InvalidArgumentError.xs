MODULE = Search::Xapian	 PACKAGE = Search::Xapian::InvalidArgumentError

PROTOTYPES: ENABLE

string
InvalidArgumentError::get_type()

string
InvalidArgumentError::get_msg()

string
InvalidArgumentError::get_context()

const char *
InvalidArgumentError::get_error_string()

void
InvalidArgumentError::DESTROY()
