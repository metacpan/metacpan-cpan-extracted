MODULE = Search::Xapian	 PACKAGE = Search::Xapian::Error

PROTOTYPES: ENABLE

string
Error::get_type()

string
Error::get_msg()

string
Error::get_context()

const char *
Error::get_error_string()

void
Error::DESTROY()

INCLUDE: XS/LogicError.xs
INCLUDE: XS/RuntimeError.xs
