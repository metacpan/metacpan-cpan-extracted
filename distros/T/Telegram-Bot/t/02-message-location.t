use Test::More;

my $msg = {
          'date' => 1471259722,
          'location' => {
                        'longitude' => '138.7',
                        'latitude' => '-34.8'
                      },
          'message_id' => 21,
          'from' => {
                    'first_name' => 'Justin',
                    'id' => 30780882,
                    'last_name' => 'Hawkins',
                    'username' => 'tardisx'
                  },
          'chat' => {
                    'type' => 'private',
                    'last_name' => 'Hawkins',
                    'id' => 30780882,
                    'username' => 'tardisx',
                    'first_name' => 'Justin'
                  }
        };

use_ok ('Telegram::Bot::Object::Message');

my $fake_brain = {}; bless $fake_brain, 'Telegram::Bot::Brain';
my $msg1 = Telegram::Bot::Object::Message->create_from_hash($msg, $fake_brain);

ok (defined $msg1->location);
is ($msg1->location->latitude, -34.8);
is ($msg1->location->longitude, 138.7);

done_testing();
