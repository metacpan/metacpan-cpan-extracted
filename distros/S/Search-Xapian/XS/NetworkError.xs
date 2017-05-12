MODULE = Search::Xapian	 PACKAGE = Search::Xapian::NetworkError

PROTOTYPES: ENABLE

string
NetworkError::get_type()

string
NetworkError::get_msg()

string
NetworkError::get_context()

const char *
NetworkError::get_error_string()

void
NetworkError::DESTROY()

INCLUDE: XS/NetworkTimeoutError.xs
