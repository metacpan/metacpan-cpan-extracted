use Test::More;

use_ok ('Telegram::Bot::Message');

my $json1 = '{ "message_id": 123456, "date": 12346, "text": "hello world" }';
my $msg1 = Telegram::Bot::Message->create_from_json($json1);

is ($msg1->date, 12346);
is ($msg1->message_id, 123456);
is ($msg1->text, "hello world");

my $json2 = '{ "message_id": 123456, "date": 12346, "from": { "id": 444 } }';
my $msg2 = Telegram::Bot::Message->create_from_json($json2);

is ($msg2->date, 12346);
is ($msg2->message_id, 123456);
ok ($msg2->from, 'has a user');
is ($msg2->from->id, 444, 'has the right id');
is ($msg2->from->first_name, undef, 'has the right id');
is ($msg2->from->last_name, undef, 'has the right id');

# chat from user
my $json3 = '{ "chat": { "id": 456, "first_name": "john" } }';
my $msg3 = Telegram::Bot::Message->create_from_json($json3);

is (ref($msg3->chat), 'Telegram::Bot::Object::User', 'isa user');
ok ($msg3->chat->is_user, 'is user');
ok (! $msg3->chat->is_group, 'is not group');

# chat from group
my $json4 = '{ "chat": { "id": -9999, "title": "johnno group" } }';
my $msg4 = Telegram::Bot::Message->create_from_json($json4);

is (ref($msg4->chat), 'Telegram::Bot::Object::Group', 'isa group');
ok ($msg4->chat->is_group, 'is group');
ok (! $msg4->chat->is_user, 'is not user');

done_testing();
