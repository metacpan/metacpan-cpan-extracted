# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format', ':subs') }

is(format_bytes(123.51),                  '123.51',  'no change');
is(format_bytes(1234567.509),             '1.18M',   'mega');
is(format_bytes(1234.51, precision => 3), '1.206K',  'kilo');
is(format_bytes(123456789.1),             '117.74M', 'bigger mega');
is(format_bytes(1234567890.1),            '1.15G',   'giga');

is(format_bytes(12.95),                   '12.95', 'test 12.95');
is(format_bytes(12.95, precision => 0),   '13',    'test 13 (precision 0)');
is(format_bytes(2048),                    '2K',    'test 2K');
is(format_bytes(9999999),                 '9.54M', 'test 9.54M');
is(format_bytes(9999999, precision => 1), '9.5M',  'test 9.5M, (precision 1)');

# Test for unit option
is(format_bytes(1048576, unit => 'K'), '1,024K',  'test 1,024K, unit K');

# Tests for iec60027 mode
is(format_bytes(123.51,       mode => "iec"), '123.51',    'no change iec');
is(format_bytes(1234567.509,  mode => "iec"), '1.18MiB',   'mebi');
is(format_bytes(1234.51,      mode => "iec",
                precision => 3),              '1.206KiB',  'kibi');
is(format_bytes(123456789.1,  mode => "iec"), '117.74MiB', 'bigger mebi');
is(format_bytes(1234567890.1, mode => "iec"), '1.15GiB',   'gibi');
is(format_bytes(1048576,      mode => "iec",
                unit => 'K'),                 '1,024KiB',  'iec unit');

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is(format_bytes(undef), "0");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::format_bytes at \Q$file\E line \d+[.]?\n});
}
