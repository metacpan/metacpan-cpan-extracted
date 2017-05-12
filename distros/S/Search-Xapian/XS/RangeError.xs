MODULE = Search::Xapian	 PACKAGE = Search::Xapian::RangeError

PROTOTYPES: ENABLE

string
RangeError::get_type()

string
RangeError::get_msg()

string
RangeError::get_context()

const char *
RangeError::get_error_string()

void
RangeError::DESTROY()
