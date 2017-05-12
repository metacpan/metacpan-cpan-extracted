use Test::More;
use Test::Exception;

use_ok('Symbol::Approx::Sub');

sub aa { 'aa' }

sub bb { 'bb' }

is(a(), 'aa', 'a() calls aa()');

is(b(), 'bb', 'b() calls bb()');

throws_ok { c() } qr/^REALLY/, 'Correct exception thrown';

done_testing;
