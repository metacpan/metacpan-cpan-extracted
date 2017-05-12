MODULE = Search::Xapian	 PACKAGE = Search::Xapian::QueryParserError

PROTOTYPES: ENABLE

string
QueryParserError::get_type()

string
QueryParserError::get_msg()

string
QueryParserError::get_context()

const char *
QueryParserError::get_error_string()

void
QueryParserError::DESTROY()
