
use Test::More tests => 7;
BEGIN { use_ok('Taint::Runtime') };

Taint::Runtime->import(qw($TAINT
                          taint_enabled
                          taint
                          untaint
                          is_tainted
                          ));

ok(! $TAINT, "Not on");

ok(! taint_enabled(), "Taint is Not on yet");

$TAINT = 1;

ok(taint_enabled(), "Taint is On");

$TAINT = 0;

ok(! taint_enabled(), "Taint disabled");

{
  local $TAINT = 1;

  ok(taint_enabled(), "Taint is On");

}

ok(! taint_enabled(), "Taint disabled");
