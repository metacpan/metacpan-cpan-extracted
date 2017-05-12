use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

filters {
    test_trim => [qw/trim/],
};

run {
    my $block = shift;
    is($block->test_trim, $block->expected_trim);
};

done_testing;
__END__

===
--- test_trim

xxx


--- expected_trim
xxx
--- test_
