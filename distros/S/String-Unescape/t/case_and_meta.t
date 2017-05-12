use Test::More;
use Test::Exception;

my @case = (
    ['ABC\lABC\labc\l', '\l'],
    ['ABC\uABC\uabc\u', '\u'],
    ['ABC\LABC\Eabc\Labc\EABC\LABC', '\L'],
    ['ABC\UABC\Eabc\Uabc\EABC\Uabc', '\U'],
    ['[]\Q[]\E[]\Q[]\E[]\Q[]', '\Q'],
    ['[ABC]\Q[abc]\U[ABC][abc]\E[ABC]\E[abc]', 'nested \Q, \U'],
    ['This \Qquoting \ubusiness \Uhere isn\'t quite\E done yet,\E is it?', 'nested \Q and \E from perlop'],
# [from 5.16]
    ['ABC\FABC\Eabc\Fabc\EABC\FABC', '\F'],
);

plan tests => 1 + 2 * @case;

use_ok 'String::Unescape';

foreach my $str (@case) {
    my $expected = eval "\"$str->[0]\"";
    my $got = String::Unescape::unescape($str->[0]);
    is($got, $expected, "func: $str->[1]");
    $got = String::Unescape->unescape($str->[0]);
    is($got, $expected, "class method: $str->[1]");
}
