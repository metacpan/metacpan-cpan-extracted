# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format', ':subs') }

is(format_number(123456.51),       '123,456.51',     'thousands');
is(format_number(1234567.509, 2),  '1,234,567.51',   'rounding');
is(format_number(12345678.5, 2),   '12,345,678.5',   'one digit');
is(format_number(123456789.51, 2), '123,456,789.51', 'hundreds of millions');
is(format_number(1.23456789, 6),   '1.234568',       'six digit rounding');
is(format_number('1.2300', 7, 1),  '1.2300000',      'extra zeroes');
is(format_number(.23, 7, 1),       '0.2300000',      'leading zero');
is(format_number(-100, 7, 1),      '-100.0000000',   'negative with zeros');

#
# https://rt.cpan.org/Ticket/Display.html?id=40126
# The test should fail because 20 digits is too big to correctly store
# in a scalar variable without using Math::BigFloat.
#
eval { format_number(97, 20) };
like($@,
     qr/^\Qround() overflow. Try smaller precision or use Math::BigFloat/,
     "round overflow");

#
# https://rt.cpan.org/Ticket/Display.html?id=48038
# Test with warnings enabled - expect a warning when called with undef
#
{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is(format_number(undef), "0");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::format_number at \Q$file\E line \d+[.]?\n});
}

#
# https://rt.cpan.org/Ticket/Display.html?id=48038
# Test again with warnings disabled to see if we do NOT get the warning
#
{
    no warnings "uninitialized";
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is(format_number(undef), "0");
    my $file = __FILE__;
    is("@warnings", "");
}
