use Test::More tests => 2 + 10*2;
BEGIN { $^W = 1 }
use strict;

my $module = 'Regexp::Exhaustive';

require_ok($module);
use_ok($module, 'exhaustive');

{
    my $str = 'abcde';
    my $re = qr/(.)(.)(.)/;
    my $vars = [qw($1 $2)];
    my @facit = (
        [qw/ a b /],
        [qw/ b c /],
        [qw/ c d /],
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = [qw($1)];
    my @facit = qw/ a b c d /;

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars");
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = [qw(@-)];
    my @facit = (
        [ 0, 0, 1 ],
        [ 1, 1, 2 ],
        [ 2, 2, 3 ],
        [ 3, 3, 4 ],
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = [qw($1 @-)];
    my @facit = (
        [ 'a', [ 0, 0, 1 ] ],
        [ 'b', [ 1, 1, 2 ] ],
        [ 'c', [ 2, 2, 3 ] ],
        [ 'd', [ 3, 3, 4 ] ],
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{

    my $str = '1234';
    my $re = qr/(?:(.))??/;
    my $count  = exhaustive($str => qr/$re/, '$1');
    my @result = exhaustive($str => qr/$re/, '$1');
    my @facit = (undef, 1, undef, 2, undef, 3, undef, 4, undef);
    is_deeply(\@result, \@facit);
    is($count, @facit);
}
{
    my $str = 'abcde';
    my $re = qr/./;
    my $vars = [qw($`)];
    my @facit = (
        '',
        'a',
        'ab',
        'abc',
        'abcd',
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/./;
    my $vars = [qw($')];
    my @facit = (
        'bcde',
        'cde',
        'de',
        'e',
        '',
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/(.)(.)/;
    my $vars = [qw($&)];
    my @facit = qw/
        ab
        bc
        cd
        de
    /;

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/(?:)/;
    my $vars = [qw($&)];
    my @facit = ('') x (1 + length $str);

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
{
    my $str = 'abcde';
    my $re = qr/(?:)/;
    my $vars = [qw($' $')];
    my @facit = (
        [ ('abcde') x 2 ],
        [ ('bcde') x 2 ],
        [ ('cde') x 2 ],
        [ ('de') x 2 ],
        [ ('e') x 2 ],
        [ ('') x 2 ],
    );

    my $count = exhaustive($str => qr/$re/, @$vars);
    is($count, @facit, "$str => $re, @$vars (scalar)");

    my @result = exhaustive($str => qr/$re/, @$vars);
    is_deeply(\@result, \@facit, "$str => $re, @$vars (list)");
}
