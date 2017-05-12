MODULE = Search::Xapian	 PACKAGE = Search::Xapian::SerialisationError

PROTOTYPES: ENABLE

string
SerialisationError::get_type()

string
SerialisationError::get_msg()

string
SerialisationError::get_context()

const char *
SerialisationError::get_error_string()

void
SerialisationError::DESTROY()
