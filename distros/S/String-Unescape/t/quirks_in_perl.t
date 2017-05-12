use Test::More;
use Test::Exception;

my @case = (
# 1)
#
# \L in \U, and vice versa, are not stacked.
# It is treated as a switch of the current case conversion.
# All \Q, \L, \U and \F (if available) modifiers from the prior \L, \U or \F become to have no effect
# then restart the new \L, \U or \F conversion. By this module, stacked.
# For example, "\LA\Ua\LA\Ea\EA\E" produces 'aAaaA' by Perl and 'aaaaa' by this module.
    ['[ABC]\Q[abc]\U[ABC]\L[abc][A\lBC]\E[a\ubc]\E[ABC]\E[abc]', 'nested \L and \U'],

# 2)
#
# \L\u is converted as \u\L, and \U\l as \l\U.
    ['\L\uBBBB\EaAaA\U\lCCCC\EaAaA', '\L\u and \U\l'],
);

plan tests => 1 + 2 * @case;

use_ok 'String::Unescape';

local $TODO = 'They are quirks in perl, maybe surprising people, except for perl hackers';

foreach my $str (@case) {
    my $expected = eval "\"$str->[0]\"";
    my $got = String::Unescape::unescape($str->[0]);
    is($got, $expected, "func: $str->[1]");
    $got = String::Unescape->unescape($str->[0]);
    is($got, $expected, "class method: $str->[1]");
}
