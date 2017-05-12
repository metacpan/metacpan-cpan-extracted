# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format', ':subs') }

cmp_ok(unformat_number('123,456.51'),        '==', 123456.51,   'num');
cmp_ok(unformat_number('US$ 12,345,678.51'), '==', 12345678.51, 'curr');

ok(! defined unformat_number('US$###,###,###.##'), 'overflow picture');

cmp_ok(unformat_number('-123,456,789.51'), '==', -123456789.51,'neg');

cmp_ok(unformat_number('1.5K'), '==', 1536,      'kilo');
cmp_ok(unformat_number('1.3M'), '==', 1363148.8, 'mega');

my $x = Number::Format->new;
$x->{neg_format} = '(x)';
cmp_ok($x->unformat_number('(123,456,789.51)'),
       '==', -123456789.51,'neg paren');

cmp_ok(unformat_number('(123,456,789.51)'),
       '==', 123456789.51,'neg default');

cmp_ok(unformat_number("4K", base => 1024), '==', 4096, '4x1024');
cmp_ok(unformat_number("4K", base => 1000), '==', 4000, '4x1000');
cmp_ok(unformat_number("4KiB", base => 1024), '==', 4096, '4x1024 KiB');
cmp_ok(unformat_number("4KiB", base => 1000), '==', 4000, '4x1000 KiB');
cmp_ok(unformat_number("4G"), '==', 4294967296, '4G');
cmp_ok(unformat_number("4G", base => 1), '==', 4, 'base 1');

eval { unformat_number("4G", base => 1000000) };
like($@, qr/^\Qbase overflow/, "base overflow");

eval { unformat_number("4G", base => 0) };
like($@, qr/^\Qbase must be a positive integer/, "base 0");

eval { unformat_number("4G", base => .5) };
like($@, qr/^\Qbase must be a positive integer/, "base .5");

eval { unformat_number("4G", base => -1) };
like($@, qr/^\Qbase must be a positive integer/, "base neg");

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is(unformat_number(undef), undef);
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::unformat_number at \Q$file\E line \d+[.]?\n});
}
