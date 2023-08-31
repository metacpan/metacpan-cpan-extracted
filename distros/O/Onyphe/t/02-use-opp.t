use Test;
BEGIN { plan(tests => 4) }

ok(sub { eval("use OPP"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::State"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Output"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc"); $@ ? 0 : 1 }, 1, $@);
