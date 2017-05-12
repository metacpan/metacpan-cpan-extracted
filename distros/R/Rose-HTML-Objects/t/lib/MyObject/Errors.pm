package MyObject::Errors;

use Rose::HTML::Object::Errors qw(:all);
use base 'Rose::HTML::Object::Errors';

use constant MYOBJ_ERR1 => 100_000;

BEGIN { __PACKAGE__->add_errors }

1;
