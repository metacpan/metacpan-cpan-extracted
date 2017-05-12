use Test;
BEGIN { plan(tests => 5) }

ok( sub { eval("use Net::Routing;"); if ($@) { return 0; } return 1; }, 1, $@);
ok( sub { eval("use Net::Routing::Linux;"); if ($@) { return 0; } return 1; }, 1, $@);
ok( sub { eval("use Net::Routing::FreeBSD;"); if ($@) { return 0; } return 1; }, 1, $@);
ok( sub { eval("use Net::Routing::Darwin;"); if ($@) { return 0; } return 1; }, 1, $@);
ok( sub { eval("use Net::Routing::NetBSD;"); if ($@) { return 0; } return 1; }, 1, $@);
