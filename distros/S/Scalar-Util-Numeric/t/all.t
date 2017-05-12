#!/usr/bin/env perl

use strict;
use warnings;

use Config;
use Math::BigInt;
use Math::Complex;
use Test::More tests => 74;

use overload
    '""'     => sub { '' . $_[0]->[0] },
    '0+'     => sub { $_[0]->[0] },
    fallback => 1;

sub new {
    my $class = shift;
    bless [ @_ ], $class;
}

# only debug the value if one or more of its tests fail
sub diag_if_fail($@) {
    my $diag = shift;
    my $fail = 0;

    for my $test (@_) {
        ++$fail unless ($test->());
    }

    if ($fail) {
        $diag = [ $diag ] unless (ref $diag);
        diag $_ for @$diag;
    }
}

use_ok('Scalar::Util::Numeric', qw(:all));

# test overloading
my $integer = __PACKAGE__->new(42);
ok($integer, '$integer is set');
ok($integer == $integer, '$integer == $integer');
ok($integer == 42, '$integer == 42');
isa_ok($integer, __PACKAGE__);

my $float = __PACKAGE__->new(3.1415927);
ok($float, '$float is set');
ok($float == $float, '$float == $float');
ok($float == 3.1415927, '$float == 3.1415927');
isa_ok($float, __PACKAGE__);

my $uvmax = Scalar::Util::Numeric::uvmax();

ok(defined($uvmax), 'uvmax is defined');

my $uvmax_plus_one = Math::BigInt->new($uvmax)->badd(1)->bstr();

ok(defined($uvmax_plus_one), 'uvmax + 1 is defined');

my $infinity = do {
    no warnings 'once';
    $Math::Complex::Inf;
};

ok(defined($infinity), 'infinity is defined');

is (isnum(0), 1, 'isnum(0)');
is (isnum(1), 1, 'isnum(1)');
is (isnum(-1), 9, 'isnum(-1)');
is (isnum('0.00'), 5, "isnum('0.00')");
is (isnum(undef), 0, "isnum(undef)");
is (isnum('A'), 0, "isnum('A')");
is (isnum('A0'), 0, "isnum('A0')");
is (isnum('0A'), 0, "isnum('0A')");
is (isnum(sub { }), 0, "isnum(sub { })");
is (isnum([]), 0, 'isnum([])');
is (isnum({}), 0, 'isnum({})');
is (isnum($integer), 1, "isnum(\$integer)");
is (isnum($float), 5, "isnum(\$float)");

diag_if_fail "UV_MAX: '$uvmax'" =>
    sub { is (isuv($uvmax), 1, 'isuv($uvmax)') },
    sub { is (isuv(-1), 1, "isuv(-1)") };

diag_if_fail [ "UV_MAX: '$uvmax'", "UV_MAX + 1: '$uvmax_plus_one'" ] =>
    sub { is (isbig($uvmax), 0, "isbig(\$uvmax)") },
    sub { is (isbig($uvmax_plus_one), 1, "isbig(\$uvmax + 1)") };

is (isfloat(3.1415927), 1, "isfloat(3.1415927)");
is (isfloat(-3.1415927), 1, "isfloat(-3.1415927)");
is (isfloat(3), 0, "isfloat(3)");
is (isfloat("1.0"), 1, "isfloat('1.0')");
is (isfloat($float), 1, "isfloat(\$float)");

is (isneg(-1), 1, "isneg(-1)");
is (isneg(-3.1415927), 1, "isneg(-3.1415927)");
is (isneg(1), 0, "isneg(1)");
is (isneg(3.1415927), 0, "isneg(3.1415927)");

diag_if_fail "INFINITY: '$infinity'" =>
    sub { is (isinf('Inf'), 1, "isinf('Inf')") },
    sub { is (isinf(3.1415927), 0, "isinf(3.1415927)") },
    sub { is (isinf($infinity), 1, 'isinf($Math::Complex::Inf)') };

is (isint(-99), -1, "isint(-99) == -1");
is (isint(0), 1, "isint(0)");
is (isint(3.1415927), 0, "isint(3.1415927)");
is (isint(-3.1415927), 0, "isint(-3.1415927)");
is (isint($uvmax), 1, 'isint($uvmax)');
is (isint($infinity), 0, 'isint($Math::Complex::Inf)');
is (isint("1.0"), 0, "isint('1.0')");
is (isint($integer), 1, "isint(\$integer)");
is (isint($float), 0, "isint(\$float)");

SKIP: {
    skip ('NaN is not supported by this platform', 2) unless($Config{d_isnan});

    # this also tests handling of objects with overloaded stringification
    my $nan = Math::BigInt->bnan;

    diag_if_fail "NAN: '$nan'" =>
        sub { is (isnan('NaN'), 1, "isnan('NaN')") },
        sub { is (isnan(42), 0, "isnan(42)") };
}

# test the assumed Inf/NaN values on Windows
SKIP: {
    skip ('Windows only', 10) unless($^O eq 'MSWin32');

    my $infinity = '1.#INF';

    diag_if_fail "INFINITY: '$infinity'" =>
        sub { is (isinf($infinity), 1, "isinf('$infinity')") }, 
        sub { is (isinf("-$infinity"), 1, "isinf('-$infinity')") }, 
        sub { is (isinf(3.1415927), 0, "isinf(3.1415927)") },
        sub { is (isinf(42), 0, "isinf(42)") },
        sub { is (isint($infinity), 0, "isint('$infinity')") },
        sub { is (isint("-$infinity"), 0, "isint('-$infinity')") };

    my $nan = '1.#IND';

    diag_if_fail "NaN: '$nan'" =>
        sub { is (isnan($nan), 1, "isnan('$nan')") },
        sub { is (isnan("-$nan"), 1, "isnan('-$nan')") },
        sub { is (isnan(3.1415927), 0, "isnan(3.1415927)") },
        sub { is (isnan(42), 0, "isnan(42)") };
}

# throw in some near-misses (wrong spelling) for the Win32 Inf and NaN
# these should be invalid numbers on all platforms
# note that letter-case variants are specifically permitted
for my $fail ('1.#IMD', '-1.#IMD', '1.#IMF', '-1.#IMF') {
    ok !isint($fail), "!isint($fail)";
    ok !isinf($fail), "!isinf($fail)";
    ok !isnan($fail), "!isnan($fail)";
}
