use Test::More;
use Test::Exception;

my $msg = {
          'chat' => {
                    'first_name' => 'Justin',
                    'username' => 'tardisx',
                    'last_name' => 'Hawkins',
                    'type' => 'private',
                    'id' => 30780882
                  },
          'photo' => [
                     {
                       'width' => 60,
                       'file_id' => 'AgADAwAD07MxG9Kt1QExdrEfe9DPEKj66yoABFhztsdgapt7BUIBAAEC',
                       'file_size' => 1447,
                       'height' => 90
                     },
                     {
                       'width' => 213,
                       'file_id' => 'AgADAwAD07MxG9Kt1QExdrEfe9DPEKj66yoABG2S1YlvFPMwBkIBAAEC',
                       'height' => 320,
                       'file_size' => 18236
                     },
                     {
                       'height' => 450,
                       'file_size' => 20746,
                       'width' => 300,
                       'file_id' => 'AgADAwAD07MxG9Kt1QExdrEfe9DPEKj66yoABJF1xS56AdcVBEIBAAEC'
                     }
                   ],
          'date' => 1471263837,
          'from' => {
                    'last_name' => 'Hawkins',
                    'id' => 30780882,
                    'first_name' => 'Justin',
                    'username' => 'tardisx'
                  },
          'message_id' => 24
        };

use_ok ('Telegram::Bot::Object::Message');

my $fake_brain = {}; bless $fake_brain, 'Telegram::Bot::Brain';
my $msg1 = Telegram::Bot::Object::Message->create_from_hash($msg, $fake_brain);

ok (defined $msg1->photo);
is ($msg1->photo->[0]->file_size, 1447);
is ($msg1->photo->[1]->file_size, 18236);
is ($msg1->photo->[2]->file_size, 20746);
is ($msg1->photo->[2]->file_id, 'AgADAwAD07MxG9Kt1QExdrEfe9DPEKj66yoABJF1xS56AdcVBEIBAAEC');

my $bad_photo = Telegram::Bot::Object::PhotoSize->new(image => "notfound.png");
# throws_ok ( sub { $bad_photo->as_hashref }, qr/no such file 'notfound.png'/, 'local image not found' );

done_testing();
