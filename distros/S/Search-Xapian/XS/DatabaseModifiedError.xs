MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseModifiedError

PROTOTYPES: ENABLE

string
DatabaseModifiedError::get_type()

string
DatabaseModifiedError::get_msg()

string
DatabaseModifiedError::get_context()

const char *
DatabaseModifiedError::get_error_string()

void
DatabaseModifiedError::DESTROY()
