MODULE = Search::Xapian	 PACKAGE = Search::Xapian::FeatureUnavailableError

PROTOTYPES: ENABLE

string
FeatureUnavailableError::get_type()

string
FeatureUnavailableError::get_msg()

string
FeatureUnavailableError::get_context()

const char *
FeatureUnavailableError::get_error_string()

void
FeatureUnavailableError::DESTROY()
