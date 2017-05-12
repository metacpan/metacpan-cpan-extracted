package MyObject;

use MyObject::Errors qw(:all);
use MyObject::Messages qw(:all);

use base 'Rose::HTML::Object';

use Rose::HTML::Object::Message::Localizer;

__PACKAGE__->localizer(
  Rose::HTML::Object::Message::Localizer->new(
    messages_class => 'MyObject::Messages',
    errors_class   => 'MyObject::Errors'));

# Checked by the test suite
our $MYOBJ_MSG1 = MYOBJ_MSG1;
our $MYOBJ_ERR1 = MYOBJ_ERR1;

1;

__DATA__
[% LOCALE en %]

MYOBJ_MSG1 = "This is my object msg 1: [2], [1]"

[% LOCALE xx %]

MYOBJ_MSG1 = "C'est mon object\nmsg 1: [b], [a]"


