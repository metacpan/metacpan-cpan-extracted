use strict;
use warnings;
use Test::More;
use Switch::Declare;

is( (switch ("abc123") { case /\d/ { "has-digit" } default { "none" } }),
    "has-digit", "regex match" );

is( (switch ("abcdef") { case /\d/ { "has-digit" } default { "none" } }),
    "none", "regex no-match -> default" );

# anchors
is( (switch ("12345") { case /^\d+$/ { "all-digits" } default { "no" } }),
    "all-digits", "anchored regex" );

# flags
is( (switch ("HELLO") { case /^hello$/i { "ci" } default { "no" } }),
    "ci", "case-insensitive flag" );

is( (switch ("Hello") { case /^hello$/ { "cs" } default { "no" } }),
    "no", "without flag is case-sensitive" );

# slash inside the pattern (escaped)
is( (switch ("a/b") { case /a\/b/ { "slash" } default { "no" } }),
    "slash", "escaped slash in regex" );

done_testing;
