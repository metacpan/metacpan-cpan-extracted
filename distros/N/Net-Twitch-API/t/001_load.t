
use Test::More tests => 2;

use lib 'lib';

BEGIN { use_ok( 'Net::Twitch::API' ); }

my $object = Net::Twitch::API->new( access_token => 'test', client_id => 'test' );
isa_ok ($object, 'Net::Twitch::API');


