use Test::More;
use Test::Exception;

my $msg = {
    'chat_type' => "group",
    'from'      => {
        'first_name'    => "Bob",
        'id'            => 1234,
        'language_code' => "en",
        'last_name'     => "",
        'username'      => "Bob",
    },
    'id'       => 123,
    'offset'   => "",
    'query'    => "foo",
    'location' => {
        'longitude' => '138.7',
        'latitude'  => '-34.8'
    },

};

use_ok('Telegram::Bot::Object::InlineQuery');

my $fake_brain = {};
bless $fake_brain, 'Telegram::Bot::Brain';
my $msg1 =
  Telegram::Bot::Object::InlineQuery->create_from_hash( $msg, $fake_brain );

ok( defined $msg1->query );
is( $msg1->query,               'foo' );
is( $msg1->from->first_name,    'Bob' );
is( $msg1->chat_type,           'group' );
is( $msg1->id,                  123 );
is( $msg1->location->longitude, '138.7' );

done_testing();
