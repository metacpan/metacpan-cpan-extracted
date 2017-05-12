package MyObject::Messages;

use Rose::HTML::Object::Messages qw(:all);
use base 'Rose::HTML::Object::Messages';

use constant MYOBJ_MSG1 => 100_000;

BEGIN { __PACKAGE__->add_messages }

1;
