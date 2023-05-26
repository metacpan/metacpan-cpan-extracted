# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format') }

my $x = Number::Format->new;
$x->{neg_format}='-x';
is($x->format_negative(123456.51),      '-123456.51',   'negative');
is($x->format_number(-.509),            '-0.51',        'neg round');
$x->{decimal_digits}=5;
is($x->format_negative(.5555),          '-0.5555',      'neg no fill');
$x->{decimal_fill}=1;
is($x->format_number(-.5555),           '-0.55550',     'neg fill');
$x->{neg_format}='(x)';
is($x->format_number(-1),               '(1.00000)',    'neg paren');
is($x->format_number(-.5),              '(0.50000)',    'neg paren zero');

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is($x->format_negative(undef), "(0)");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::format_negative at \Q$file\E line \d+[.]?\n});
}
