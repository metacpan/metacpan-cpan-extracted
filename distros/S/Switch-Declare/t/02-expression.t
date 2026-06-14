use strict;
use warnings;
use Test::More;
use Switch::Declare;

# expression form yields the matched block's value
my $label = switch (404) {
    case 200 { "ok" }
    case 404 { "missing" }
    default  { "other" }
};
is( $label, "missing", "expression value" );

# value is the last expression of the block
my $v = switch (1) { case 1 { my $x = 10; $x * 2 } default { 0 } };
is( $v, 20, "block value is last expression" );

# list context: a block returning a list flattens through
my @l = switch (1) { case 1 { (4,5,6) } default { () } };
is_deeply( \@l, [4,5,6], "list-context return" );

# usable inline within a larger expression
my $n = 1 + switch (2) { case 2 { 40 } default { 0 } } + 1;
is( $n, 42, "switch as a sub-expression" );

done_testing;
