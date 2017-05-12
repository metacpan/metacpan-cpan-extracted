use strict;
use warnings;
use utf8;
use Test::Base::SubTest;

plan tests => 3;

run {
    my $block = shift;
    is($block->input, 1);
};

__END__

===
--- input: 1

===
--- input: 1

===
--- LAST
--- input: 1

===
--- input: 2

