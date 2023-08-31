use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use Class::Gomor"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Class::Gomor::Array"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Onyphe"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use Onyphe::Api"); $@ ? 0 : 1 }, 1, $@);
