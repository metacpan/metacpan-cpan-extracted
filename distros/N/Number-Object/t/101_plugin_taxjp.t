use strict;
use warnings;
use Test::Base;

use Number::Object;
Number::Object->load_components(qw/ Autocall /);
Number::Object->load_plugins(qw/ Tax::JP /);

filters { price => [qw/ chop /], tax => [qw/ chop /] };

plan tests => 4 * blocks;

run {
    my $block = shift;

    my $price = Number::Object->new($block->price);
    is $price->call('tax'), $block->tax;
    is $price->call('include_tax'), $block->price + $block->tax;
    is $price->tax, $block->tax;
    is $price->include_tax, $block->price + $block->tax;

}

__END__

===
--- price
100
--- tax
8

===
--- price
8892
--- tax
711

===
--- price
10000
--- tax
800
