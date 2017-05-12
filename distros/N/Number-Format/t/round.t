# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format', ':subs') }

use constant PI => 4*atan2(1,1);

ok(compare_numbers(round(0), 0),                           'identity 0');
ok(compare_numbers(round(1), 1),                           'identity 1');
ok(compare_numbers(round(-1), -1),                         'identity -1');
ok(compare_numbers(round(PI,2), 3.14),                     'pi prec=2');
ok(compare_numbers(round(PI,3), 3.142),                    'pi prec=3');
ok(compare_numbers(round(PI,4), 3.1416),                   'pi prec=4');
ok(compare_numbers(round(PI,5), 3.14159),                  'pi prec=5');
ok(compare_numbers(round(PI,6), 3.141593),                 'pi prec=6');
ok(compare_numbers(round(PI,7), 3.1415927),                'pi prec=7');
ok(compare_numbers(round(123456.512), 123456.51),          'precision=0' );
ok(compare_numbers(round(-1234567.509, 2), -1234567.51),   'negative thous' );
ok(compare_numbers(round(-12345678.5, 2), -12345678.5),    'negative tenths' );
ok(compare_numbers(round(-123456.78951, 4), -123456.7895), 'precision=4' );
ok(compare_numbers(round(123456.78951, -2), 123500),       'precision=-2' );

# Without the 1e-10 "epsilon" value in round(), the floating point
# number math will result in 1 rather than 1.01 for this test.
is(round(1.005, 2), 1.01, 'string-eq' );

# Compare numbers within an epsilon value to avoid false negative
# results due to floating point math
sub compare_numbers
{
    my($p, $q) = @_;
    return abs($p - $q) < 1e-10;
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is(round(undef), "0");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::round at \Q$file\E line \d+[.]?\n});
}
