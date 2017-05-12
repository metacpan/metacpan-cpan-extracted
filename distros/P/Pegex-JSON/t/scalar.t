use Test::More tests => 3;

use Pegex::JSON;

is + Pegex::JSON->new->load('["a\bc\nd"]')->[0], "a\x{08}c\x0ad",
    "Parse backslash escapes work";

is + Pegex::JSON->new->load('["\u2122"]')->[0], "\x{2122}",
    "Unicode escape works";

is + Pegex::JSON->new->load('["\u0001\uf4a1"]')->[0], "\x{1f4a1}",
    "Unicode escape works with surrogate pairs";
