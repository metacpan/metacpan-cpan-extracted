package MyObject::BadMessages2;

use Rose::HTML::Object::Messages qw(:all);
use base 'Rose::HTML::Object::Messages';

use constant FIELD_LABEL => 9999;

BEGIN { __PACKAGE__->add_messages }

1;
