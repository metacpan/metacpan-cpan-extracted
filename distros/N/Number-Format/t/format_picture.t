# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format') }

my $pic = 'US$##,###,###.##';
my $x = Number::Format->new;
$x->{neg_format} = '-x';
is($x->format_picture(123456.512, $pic),    'US$    123,456.51',  'thou');
is($x->format_picture(-1234567.509, $pic),  'US$ -1,234,567.51',  'neg');
is($x->format_picture(12345678.5, $pic),    'US$ 12,345,678.50',  'zero');
is($x->format_picture(123456789.51, $pic),  'US$ **,***,***.**',  'pos over');
is($x->format_picture(-123456789.51, $pic), 'US$-**,***,***.**',  'neg over');
is($x->format_picture(1023012.34, $pic),    'US$  1,023,012.34',  'million');
is($x->format_picture(120450.789012, $pic), 'US$    120,450.79',  'pos rnd');
is($x->format_picture(-120450.789012, $pic),'US$   -120,450.79',  'neg rnd');
$x->{neg_format} = '(x)';
is($x->format_picture(120450.789012, $pic), 'US$    120,450.79 ', 'pos paren');
is($x->format_picture(-120450.789012, $pic),'US$   (120,450.79)', 'neg paren');
$pic = '#';
is($x->format_picture(1, $pic), ' 1 ',  'one digit 1');
is($x->format_picture(2, $pic), ' 2 ',  'one digit 2');

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is($x->format_picture(undef, $pic), " 0 ");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::format_picture at \Q$file\E line \d+[.]?\n});
}
