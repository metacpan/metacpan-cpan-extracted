use strict;
use warnings;
use Test::Base;

use Number::Object;

filters { data => [qw/ chop /], comma => [qw/ chop /] };

plan tests => 2 * blocks;

run {
    my $block = shift;

    my $price = Number::Object->new($block->data);
    is $price->filtered('comma'), $block->comma;
    is $price->filtered('comma', 'comma'), $block->comma;
}

__END__

===
--- data
100
--- comma
100

===
--- data
1000
--- comma
1,000


===
--- data
12345678
--- comma
12,345,678
