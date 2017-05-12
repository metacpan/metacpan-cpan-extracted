package MyObject::BadMessages;

use Rose::HTML::Object::Messages qw(:all);
use base 'Rose::HTML::Object::Messages';

use constant MYOBJ_MSG1 => 2;

BEGIN { __PACKAGE__->add_messages }

1;
