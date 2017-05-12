package MyObject::Errors2;

use Rose::HTML::Object::Errors qw(:all);
use base 'Rose::HTML::Object::Errors';

use constant MYOBJ_ERR2 => 100_001;

BEGIN { __PACKAGE__->add_errors }

1;
