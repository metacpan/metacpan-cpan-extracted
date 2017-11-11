
use warnings;
use strict;
use Test::More tests => 48;

# Check if module loads ok
BEGIN { use_ok('Number::FormatEng', qw(format_pref)) }

is(format_pref(0x55     )        , '85');
is(format_pref(-85.0    )        , '-85');
is(format_pref(5000     )        , '5k');
is(format_pref(9999     )        , '9.999k');
is(format_pref(10_000   )        , '10k');
is(format_pref(7777     )        , '7.777k');
is(format_pref(-0.04567 )        , '-45.67m');
is(format_pref(456789   )        , '456.789k');
is(format_pref(2308     )        , '2.308k', 'Bug: RT 123532');

# examples from pod
is(format_pref(1234     )        , '1.234k');
is(format_pref(-0.0004  )        , '-400u');
is(format_pref(1.27e13  )        , '12.7T');
is(format_pref(7.5e60   )        , '7.5e60');

# Check all prefixes

is(format_pref(1e4      )        , '10k');
is(format_pref(1e+5     )        , '100k');
is(format_pref(1e6      )        , '1M');
is(format_pref(1e10     )        , '10G');
is(format_pref(1e13     )        , '10T');
is(format_pref(1e16     )        , '10P');
is(format_pref(1e18     )        , '1E');
is(format_pref(1e22     )        , '10Z');
is(format_pref(1e25     )        , '10Y');
is(format_pref(1e26     )        , '100Y');

is(format_pref(1e-3     )        , '1m');
is(format_pref(1e-6     )        , '1u');
is(format_pref(1e-7     )        , '100n');
is(format_pref(1e-10    )        , '100p');
is(format_pref(1e-14    )        , '10f');
is(format_pref(1e-17    )        , '10a');
is(format_pref(1e-20    )        , '10z');
is(format_pref(1e-23    )        , '10y');
is(format_pref(1e-24    )        , '1y');

is(format_pref(-0       )        , '0');
is(format_pref(0        )        , '0');
is(format_pref(0.00     )        , '0', 'decimal not preserved');

# Out-of-range
is(format_pref(1e27     )       , '1e27');
is(format_pref(1e-33    )       , '1e-33');
is(format_pref(-1e-26   )       , '-10e-27');
is(format_pref(1e-25    )       , '100e-27');

is(format_pref(999e24   )       , '999Y');
is(format_pref(-345678, 100)    , '-345.678k', 'ignore extra arg');


# Check error messages

$@ = '';
eval { my $str = format_pref() };
like($@, qr/requires numeric input/, 'die if no input');

$@ = '';
eval { my $str = format_pref(' ') };
like($@, qr/not numeric/, 'die if input only has whitespace');

$@ = '';
eval { my $str = format_pref(undef) };
like($@, qr/requires numeric input/, 'die if no undef');

$@ = '';
eval { my $str = format_pref('foo777') };
like($@, qr/not numeric/, 'die if input does not look like a number');

$@ = '';
eval { my $str = format_pref([3]) };
like($@, qr/Error: .* not numeric/, 'die if array ref');

$@ = '';
eval { my $str = format_pref("\x22") };
like($@, qr/Error: .* not numeric/, 'die if control char');

