
# purpose: tests Mnet::Stanza

# required modules
use warnings;
use strict;
use Mnet::Stanza;
use Test::More tests => 12;

# check trim function
Test::More::is(
    Mnet::Stanza::trim("
        double  spaces
         indented
          trailing" . " " . "
    "), "double spaces\n indented\n  trailing", "trim"
);

# check parse function, returning the correct number of list elements
#   stanza2 should be returned under stanza1, not as a separate element
my @list = Mnet::Stanza::parse(
    Mnet::Stanza::trim("
        extra
        stanza1
         stanza2
        extra
        stanza3
        extra
    "), qr/^\s*stanza/
);
Test::More::is(scalar(@list), 2, "parse list");

# check parse function, returning a string
Test::More::is(
    scalar(Mnet::Stanza::parse(Mnet::Stanza::trim("
        extra
        stanza1
         stanza2
        extra
        stanza3
        extra
    "), qr/^\s*stanza/)), "stanza1\n stanza2\nstanza3", "parse string"
);

# check diff function, with a variety of inputs
Test::More::is(Mnet::Stanza::diff("1\n2", "1\n2"), "", "diff same");
Test::More::is(Mnet::Stanza::diff("1\n2", "1\n3"), "line 2: 2", "diff line");
Test::More::is(Mnet::Stanza::diff(undef, ""), "undef: old", "diff undef old");
Test::More::is(Mnet::Stanza::diff("", undef), "undef: new", "diff undef new");
Test::More::is(Mnet::Stanza::diff(undef, undef) // "u", "u", "diff undef both");
Test::More::is(Mnet::Stanza::diff("1\n2", "1"), "line 2: 2", "diff extra old");
Test::More::is(Mnet::Stanza::diff("1", "1\n3"), "line 2: 3", "diff extra new");
Test::More::is(Mnet::Stanza::diff("1", "1 "), "line 1: 1", "diff spaces");
Test::More::is(Mnet::Stanza::diff("1", "1\n"), "other", "diff other");

# finished
exit;

