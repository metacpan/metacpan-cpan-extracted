MODULE = Search::Xapian	 PACKAGE = Search::Xapian::LogicError

PROTOTYPES: ENABLE

string
LogicError::get_type()

string
LogicError::get_msg()

string
LogicError::get_context()

const char *
LogicError::get_error_string()

void
LogicError::DESTROY()

INCLUDE: XS/AssertionError.xs
INCLUDE: XS/InvalidArgumentError.xs
INCLUDE: XS/InvalidOperationError.xs
INCLUDE: XS/UnimplementedError.xs
