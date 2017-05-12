use Test::More tests => 2 + 6*2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    my $str = "foo\nbar\nbaz";
    my $re = qr/^.+?$/ms;
    my $count  = exhaustive($str => qr/$re/);
    my @result = exhaustive($str => qr/$re/);
    my @facit = (
        "foo",
        "foo\nbar",
        "foo\nbar\nbaz",
        "bar",
        "bar\nbaz",
        "baz",
    );
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
{
    my $str = '1234';
    my $re = qr/(?:)/;
    my $count  = exhaustive($str => qr/$re/);
    my @result = exhaustive($str => qr/$re/);
    my @facit = ('') x 5;
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
{
    my $str = '1234';
    my $re = qr/.+/;
    my $count  = exhaustive($str => qr/$re/);
    my @result = exhaustive($str => qr/$re/);
    my @facit = qw/
        1234
        123
        12
        1
        234
        23
        2
        34
        3
        4
    /;
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
{

    my $str = '1234';
    my $re = qr/(?:(.))??/;
    my $count  = exhaustive($str => qr/$re/);
    my @result = exhaustive($str => qr/$re/);
    my @facit = (undef, 1, undef, 2, undef, 3, undef, 4, undef);
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
for (1 .. 2) {
    my $str = '123';
    my $re = qr/.*/;
    my $count  = exhaustive($str => qr/$re/);
    my @result = exhaustive($str => qr/$re/);
    my @facit = (
        '123',
        '12',
        '1',
        '',
        '23',
        '2',
        '',
        '3',
        '',
        ''
    );
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
