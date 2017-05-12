package MyObject2;

use FindBin qw($Bin);

use MyObject::Errors2 qw(:all);
use MyObject::Messages2 qw(:all);

use base 'Rose::HTML::Object';

use Rose::HTML::Object::Message::Localizer;

__PACKAGE__->localizer(
  Rose::HTML::Object::Message::Localizer->new(
    messages_class => 'MyObject::Messages2',
    errors_class   => 'MyObject::Errors2'));

# Checked by the test suite
our $MYOBJ_MSG2 = MYOBJ_MSG2;
our $MYOBJ_ERR2 = MYOBJ_ERR2;

my $id = __PACKAGE__->localizer->add_localized_error(name => 'MYOBJ_ERR3');

__PACKAGE__->localizer->add_localized_message
(
  name => 'MYOBJ_ERR3',
  id   => $id,
  text => 
  {
    en => 'x my msg 3: [2], [1]',
    xx => "mon\nmsg 3: [b], [a]",
  },
);

__PACKAGE__->localizer->add_localized_message_text
(
  name => 'MYOBJ_ERR2',
  text => 
  {
    en => 'x my msg 2: [2], [1]',
    xx => "x mon\nmsg 2: [b], [a]",
  },
);

__PACKAGE__->localizer->load_messages_from_file("$Bin/msgs.txt");

1;
