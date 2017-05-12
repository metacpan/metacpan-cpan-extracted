MODULE = Search::Xapian	 PACKAGE = Search::Xapian::NetworkTimeoutError

PROTOTYPES: ENABLE

string
NetworkTimeoutError::get_type()

string
NetworkTimeoutError::get_msg()

string
NetworkTimeoutError::get_context()

const char *
NetworkTimeoutError::get_error_string()

void
NetworkTimeoutError::DESTROY()
