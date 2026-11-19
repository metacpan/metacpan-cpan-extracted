# Test origin: AI
use v5.36;
use Test2::V0;

use Review::Helper;

like($Review::Helper::VERSION, qr{\A[0-9]+\.[0-9]{3}\z}, 'has a version');

done_testing;
