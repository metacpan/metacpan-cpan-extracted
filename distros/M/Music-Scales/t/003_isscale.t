# -*- perl -*-

# t/003_isscale.t - check mode names are ok

use Test::Simple tests => 6;
use Music::Scales;

ok(!is_scale('x'));
ok(is_scale('major'));
ok(is_scale('maj'));
ok(is_scale('minor'));
ok(is_scale('min'));
ok(is_scale('m'));

