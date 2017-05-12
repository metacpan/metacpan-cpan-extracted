
use Test::More tests => 4;
BEGIN { use_ok('Taint::Runtime') };

Taint::Runtime->import(qw($TAINT));

ok(! $TAINT, "Not on");

Taint::Runtime->import('enable');

ok($TAINT, "Taint is On");

Taint::Runtime->import('disable');

ok(! $TAINT, "Not on");
