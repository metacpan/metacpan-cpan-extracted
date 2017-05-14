use Test::More tests => 15;
use strict;

# use the module
use_ok('MyLibrary::Message');

# create a message object
my $message = MyLibrary::Message->new();
isa_ok($message, "MyLibrary::Message");

# set the the message's message
$message->message('I regret that I have but one life to give for my country.');
is($message->message(), 'I regret that I have but one life to give for my country.', 'set message()');

# set the message's date
$message->message_date('2003-09-02');
is($message->message_date(), '2003-09-02', 'set message_date()');

# set the message's global flag to true
$message->message_global('1');
is($message->message_global(), '1', 'set message_global() to t');

# set the message's global flag to false
$message->message_global('2');
is($message->message_global(), '2', 'set message_global() to f');

# save a new facet record
is($message->commit(), '1', 'commit() a new message');

# get a facet id
my $id = $message->message_id();
like ($id, qr/^\d+$/, 'get message_id()');

# get record based on an id
$message = MyLibrary::Message->new(id => $id);
is ($message->message(), 'I regret that I have but one life to give for my country.', 'get message()');
is ($message->message_date(), '2003-09-02', 'get message_date()');
is ($message->message_global(), '2', 'get message_global()');

# update a message
$message->message('How can we be sure 2 + 2 = 4?');
$message->message_date('2003-09-03');
$message->message_global('1');
$message->commit();
$message = MyLibrary::Message->new(id => $id);
is ($message->message(), 'How can we be sure 2 + 2 = 4?', 'commit() an updated message');
is ($message->message_date(), '2003-09-03', 'commit() an updated message date');
is ($message->message_global(), '1', 'commit() an updated message global');

# get messages
my @m = MyLibrary::Message->get_messages();
foreach $message (@m) { print $message->message(), "\n" }

# delete a message
is ($message->delete(), '1', 'delete() a message');


