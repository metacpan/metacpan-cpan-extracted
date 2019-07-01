use Test::More;
use utf8;

my $msg = {
  'sticker' => {
     'width' => 450,
     'thumb' => {
                'file_id' => 'AAQEABNNAAFiMAAECdbz5uq0u_TTCAACAg',
                'file_size' => 7958,
                'height' => 128,
                'width' => 112
              },
     'file_id' => 'BQADBAADNAADudGqAcoyTi47_2O3Ag',
     'emoji' => "\x{270b}",
     'file_size' => 57492,
     'height' => 512
   },
'chat' => {
  'first_name' => 'Justin',
  'username' => 'tardisx',
  'last_name' => 'Hawkins',
  'type' => 'private',
  'id' => 30780882
},
'from' => {
  'id' => 30780882,
  'last_name' => 'Hawkins',
  'username' => 'tardisx',
  'first_name' => 'Justin'
},
'message_id' => 22,
'date' => 1471261929
};

use_ok ('Telegram::Bot::Object::Message');
my $fake_brain = {}; bless $fake_brain, 'Telegram::Bot::Brain';
my $msg1 = Telegram::Bot::Object::Message->create_from_hash($msg, $fake_brain);

ok (defined $msg1->sticker);
is ($msg1->sticker->emoji, '✋');

done_testing();
