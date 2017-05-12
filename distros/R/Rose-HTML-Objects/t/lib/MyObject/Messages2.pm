package MyObject::Messages2;

use Rose::HTML::Object::Messages qw(:all);
use base 'Rose::HTML::Object::Messages';

use constant MYOBJ_MSG2 => 100_000;
use constant MYOBJ_ERR2 => 100_001;

BEGIN { __PACKAGE__->add_messages }

1;
