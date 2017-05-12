use Test::More tests => 2;
use Test::Exception;

use_ok('Net::Amazon::Recommended');
throws_ok { Net::Amazon::Recommended->new } qr/required/, 'parameter check';
