use Test;
BEGIN { plan(tests => 2) }

ok( sub { eval("use Splunklib;"); if ($@) { return 0; } return 1; }, 1, $@);
ok( sub { eval("use Splunklib::Intersplunk;"); if ($@) { return 0; } return 1; }, 1, $@);
