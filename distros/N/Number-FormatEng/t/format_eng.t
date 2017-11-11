
use warnings;
use strict;
use Test::More tests => 30;

# Check if module loads ok
BEGIN { use_ok('Number::FormatEng', qw(format_eng)) }

# Check module version number
BEGIN { use_ok('Number::FormatEng', '0.03') }

is(format_eng(99)           , '99');
is(format_eng(99999)        , '99.999e3');
is(format_eng(2.22e26)      , '222e24');
is(format_eng(-0.56e30)     , '-560e27');
is(format_eng(222e-30)      , '222e-30');
is(format_eng(" \n -0.567 \t  ") , '-567e-3', 'whitespace is trimmed');

# examples from pod
is(format_eng(1234)     , '1.234e3');
is(format_eng(-0.03)    , '-30e-3');
is(format_eng(7.8e7)    , '78e6');

# repeating decimal requires pre-formatting
is(format_eng(sprintf '%.3f', 1/3)          , '333e-3', '1/3');
is(format_eng(sprintf '%.2e', 1/3_000_000)  , '333e-9', '1/3_000_000');

is(format_eng(1e300)      , '1e300');
is(format_eng(1e-291)     , '1e-291');
is(format_eng(1e-290)     , '10e-291');
is(format_eng(1e-289)     , '100e-291');
is(format_eng(99999.99)   , '99.99999e3');
is(format_eng(-1111, 555) , '-1.111e3', 'ignore extra inputs');

# corner case: decimals not preserved
is(format_eng(1.000)    , '1'   , 'one');
is(format_eng(10.0)     , '10'  , 'ten');
is(format_eng(100.0000) , '100' , 'hundred');
is(format_eng(0.00)     , '0'   , 'zero');

# corner case: trailing zeroes not preserved
is(format_eng(5.0500) , '5.05', 'trailing zeroes');

# Check error messages

$@ = '';
eval { my $str = format_eng() };
like($@, qr/requires numeric input/, 'die if no input');

$@ = '';
eval { my $str = format_eng(' ') };
like($@, qr/not numeric/, 'die if input only has whitespace');

$@ = '';
eval { my $str = format_eng(undef) };
like($@, qr/requires numeric input/, 'die if no undef');

$@ = '';
eval { my $str = format_eng('foo777') };
like($@, qr/not numeric/, 'die if input does not look like a number');

$@ = '';
eval { my $str = format_eng([3]) };
like($@, qr/Error: .* not numeric/, 'die if array ref');

$@ = '';
eval { my $str = format_eng("\x22") };
like($@, qr/Error: .* not numeric/, 'die if control char');

