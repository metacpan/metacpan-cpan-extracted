use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

run {
    my $block = shift;
    is(uc($block->input), $block->expected);
};
done_testing;

__DATA__

===
--- input: x
--- expected: X

=== have a name
--- input: y
--- expected: Y

