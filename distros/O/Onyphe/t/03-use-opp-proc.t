use Test;
BEGIN { plan(tests => 26) }

ok(sub { eval("use OPP::Proc::Uniq"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Dedup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Exec"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Whois"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Fields"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Addcount"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Count"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Noop"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Search"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Merge"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Where"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Top"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Fieldcount"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Filter"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Expand"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Flatten"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Output"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Pivots"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Discovery"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Splitsubnet"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Regex"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Lookup"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Blocklist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Allowlist"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Addfield"); $@ ? 0 : 1 }, 1, $@);
ok(sub { eval("use OPP::Proc::Exists"); $@ ? 0 : 1 }, 1, $@);
