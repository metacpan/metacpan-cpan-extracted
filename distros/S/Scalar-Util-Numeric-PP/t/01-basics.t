#!perl

use 5.010;
use strict;
use warnings;

use Scalar::Util::Numeric::PP
    qw(isint isnum isnan isinf isneg isfloat);
use Test::More 0.98;

ok( isint(1));
ok( isint(-23));
ok( isint("\n23\n"));
ok( isint("+1"));
ok( isint(" +1 "));
ok(!isint(undef));
ok(!isint("a"));
ok(!isint("1.1"));
ok(!isint("1_000"));

ok( isfloat(1.1));
ok( isfloat("1.0"));
ok( isfloat(-23.4));
ok( isfloat(-5.61e1));
ok( isfloat(5.6e-7));
ok( isfloat(".1"));
ok( isfloat(".1e1"));
ok( isfloat("\n.1e1\n"));
ok( isfloat("-.1e-1"));
ok( isfloat(" -.1e-1 "));
ok( isfloat("-inf"));
ok( isfloat("NaN"));
ok(!isfloat(undef));
ok(!isfloat(1));
ok(!isfloat(1.0));
ok(!isfloat(-23));
ok(!isfloat("+1"));
ok(!isfloat("a"));
ok(!isfloat("1,1"));
ok(!isfloat("1_000.1"));

ok( isnum(1));
ok( isnum(-23));
ok( isnum("+1"));
ok( isnum(1.1));
ok( isnum(-23.4));
ok( isnum(-5.6e7));
ok( isnum(5.6e-7));
ok( isnum("-inf"));
ok( isnum("NaN"));
ok(!isnum(undef));
ok(!isnum("a"));
ok(!isnum("1,1"));
ok(!isnum("1_000"));
ok(!isnum("1_000.1"));

ok( isnan("nan"));
ok( isnan("nan\n"));
ok( isnan("+NAN"));
ok( isnan(" -NAN "));
ok(!isnan(undef));
ok(!isnan("inf"));

ok( isinf("inf"));
ok( isinf("+Inf"));
ok( isinf(" -Inf "));
ok( isinf(" -Infinity "));
ok(!isinf(undef));
ok(!isinf("nan"));

ok( isneg("-1"));
ok( isneg(" -Nan"));
ok( isneg("-2.3e4"));
ok(!isneg(undef));
ok(!isneg("2.3e-4"));
ok(!isneg("inf"));

DONE_TESTING:
done_testing();
