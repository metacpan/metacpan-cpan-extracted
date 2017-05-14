use Test::More;
use Test::Fatal;

use Net::Sentry::Client;

require_ok ( 'JSON' );
require_ok ( 'LWP::UserAgent' );
require_ok ( 'Digest::HMAC_SHA1' );
require_ok ( 'Compress::Zlib' );
require_ok ( 'HTTP::Request::Common' );
require_ok ( 'Data::UUID::MT' );
require_ok ( 'MIME::Base64' );

ok( my $cl = Net::Sentry::Client->new( sentry_key => 'test', remote_url => 'url' ), 'constructor_00' );

done_testing();
