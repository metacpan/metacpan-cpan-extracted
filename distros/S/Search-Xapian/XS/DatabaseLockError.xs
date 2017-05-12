MODULE = Search::Xapian	 PACKAGE = Search::Xapian::DatabaseLockError

PROTOTYPES: ENABLE

string
DatabaseLockError::get_type()

string
DatabaseLockError::get_msg()

string
DatabaseLockError::get_context()

const char *
DatabaseLockError::get_error_string()

void
DatabaseLockError::DESTROY()
