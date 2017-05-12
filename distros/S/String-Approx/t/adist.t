use String::Approx qw(adist adistr adistword adistrword);
use Test::More tests => 32;

is(adist("abc", "abc"), 0);

is(adist("abc", "abd"), 1);

is(adist("abc", "ade"), 2);

is(adist("abc", "def"), 3);

is(adistr("abc", "abd"), 1/3);

$a = adist("abc", ["abc", "abd", "ade", "def"]);

is($a->[0], 0);

is($a->[1], 1);

is($a->[2], 2);

is($a->[3], 3);

is(@$a, 4);

$a = adist(["abc", "abd", "ade", "def"], "abc");

is($a->[0], 0);

is($a->[1], 1);

is($a->[2], 2);

is($a->[3], 3);

is(@$a, 4);

$a = adist(["abc", "abd", "ade", "def"], ["abc", "abd", "ade", "def"]);

is($a->[0]->[0], 0);

is($a->[1]->[2], 2);

is($a->[2]->[1], 1);

is($a->[3]->[3], 0);

is(@$a, 4);

is(adist("abcd", "abc"), -1);

is(adistr("abcd", "abc"), -1/4);

is(adist("abcde", "abc"), -2);

is(adistr("abcde", "abc"), -2/5);

my @a = adist("abc", "abd", "ade", "def");

is($a[2], 3);

{
    my @abd = ("abd", "bad");
    my @r = adistr("abc", @abd);
    is(@r, 2);
    is($r[0], 1/3);
    is($r[1], 2/3);
}

is(adist("abc", ""), 3);
is(adist("", "abc"), 3);
is(adist("", ""), 0);

is(adist("\x{100}", ""), 1);
