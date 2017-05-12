use Test;
BEGIN { plan tests => 1 };

ok(
   sub { eval("use Net::Write::Fast;"); return $@ ? 0 : 1 },
   1,
   $@,
);
