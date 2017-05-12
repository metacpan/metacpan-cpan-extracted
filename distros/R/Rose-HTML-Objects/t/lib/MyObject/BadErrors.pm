package MyObject::BadErrors;

use Rose::HTML::Object::Errors qw(:all);
use base 'Rose::HTML::Object::Errors';

use constant MYOBJ_ERR1 => 3;

BEGIN { __PACKAGE__->add_errors }

1;
