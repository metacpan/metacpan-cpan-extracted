package MyField;

use MyObject::Errors qw(:all);
use MyObject::Messages qw(:all);

use base 'Rose::HTML::Form::Field';

use Rose::HTML::Object::Message::Localizer;

__PACKAGE__->localizer(
  Rose::HTML::Object::Message::Localizer->new(
    messages_class => 'MyObject::Messages',
    errors_class   => 'MyObject::Errors'));

1;

__DATA__
[% LOCALE en %]

FIELD_LABEL = "Dog"

[% LOCALE xx %]

FIELD_LABEL = "Chien"


