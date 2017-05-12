use 5.010;
use strict;
use warnings;
use Regexp::Grammars;
use Test::More tests => 4;

# The text to match against
my $text = 'a' . (' ' x 5) . 'z';

# This should match without backtracking
my $repop_match = qr/
    \A<TOP>\Z

    <token: TOP> <[val]> ** <sep>
    <token: sep> \s{5}
    <token: val> \w+
/x;

# This should NOT match
my $repop_nomatch = qr/
    \A<TOP>\Z

    <token: TOP> <[val]> ** <sep>
    <token: sep> \s{3}
    <token: val> \w+
/x;

# This demonstrates the expected behaviour of $repop_match
my $standard_match = qr/
    \A<TOP>\Z

    <token: TOP> <[val]> (?: <sep> <[val]> )*
    <token: sep> \s{5}
    <token: val> \w+
/x;

# This demonstrates the expected behaviour of $repop_nomatch
my $standard_nomatch = qr/
    \A<TOP>\Z

    <token: TOP> <[val]> (?: <sep> <[val]> )*
    <token: sep> \s{3}
    <token: val> \w+
/x;

ok $text =~ $repop_match   => "Repetition operator correctly matches";
ok $text !~ $repop_nomatch => "Repetition operator correctly doesn't match";

ok $text =~ $standard_match   => "Simulation correctly matches";
ok $text !~ $standard_nomatch => "Simulation correctly doesn't match";
