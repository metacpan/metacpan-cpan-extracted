
BEGIN {
    use FindBin qw($Bin);
    require "$Bin/test.pl";
    plan(tests => 3);
}

use Regexp::Fields;

SKIP: {
    skip "scope", 1;
    1 while "x\n" =~ /(?<m>.)/g;
    is "$&{m}", "\n", "don't restore PL_multiline too soon";
}


#
# Reported by Sterling Hanenkamp -- referring to %& before
# $& makes $& lose its magic.  [See perl #24237.]
#

"foo" =~ /(?<f> foo)/;
is $&, $&{f};
is $&, "foo";
