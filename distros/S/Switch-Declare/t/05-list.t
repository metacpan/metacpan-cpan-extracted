use strict;
use warnings;
use Test::More;
use Switch::Declare;

# string membership
is( (switch ("b") { case ["a","b","c"] { "in" } default { "out" } }), "in",  "string in list" );
is( (switch ("z") { case ["a","b","c"] { "in" } default { "out" } }), "out", "string not in list" );

# numeric membership
is( (switch (7) { case [1,3,7,9] { "odd" } default { "no" } }), "odd", "number in list" );
is( (switch (4) { case [1,3,7,9] { "odd" } default { "no" } }), "no",  "number not in list" );

# single-element list
is( (switch (1) { case [1] { "one" } default { "no" } }), "one", "single-element list" );

done_testing;
