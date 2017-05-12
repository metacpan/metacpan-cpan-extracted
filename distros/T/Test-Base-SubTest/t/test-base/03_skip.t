use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

run {
    my $block = shift;
    is($block->input, 1);
};

done_testing;

__END__

===
--- input: 1

===
--- SKIP
--- input: 2

===
--- input: 1
