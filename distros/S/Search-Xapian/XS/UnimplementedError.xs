MODULE = Search::Xapian	 PACKAGE = Search::Xapian::UnimplementedError

PROTOTYPES: ENABLE

string
UnimplementedError::get_type()

string
UnimplementedError::get_msg()

string
UnimplementedError::get_context()

const char *
UnimplementedError::get_error_string()

void
UnimplementedError::DESTROY()
