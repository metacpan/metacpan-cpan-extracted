use strict;
use warnings;
use utf8;
use Test::Base::SubTest;
use Test::More;

SKIP: {
    skip 'Not implemented', 1;
    run {
        my $block = shift;
        is($block->input, 'MMM');
    };
};

done_testing;
__END__

===
--- input: YYY

===
--- ONLY
--- input: MMM

===
--- input: ZZZ
