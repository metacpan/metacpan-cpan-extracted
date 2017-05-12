use Test::More tests => 2 + 3;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    my @result = exhaustive("foo\nbar\nbaz" => qr/(?>.+)/);
    my @facit = qw/
        foo oo o
        bar ar r
        baz az z
    /;
    is_deeply(\@result, \@facit);
}
{
    my @result = exhaustive('1234' => qr/(?>)/);
    my @facit = ('') x 5;
    is_deeply(\@result, \@facit);
}
{
    my $str = '1234';
    my $re = qr/(?>.??)/;
    my @result = exhaustive($str => qr/(?>$re)/);
    my @facit = $str =~ /(?=$re)/g;
    is_deeply(\@result, \@facit);
}
