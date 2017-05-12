use strict;
use warnings;
use Test::Base;

use Number::Object;

filters { l => [qw/ chop /], r => [qw/ chop /] };

my $plan = 4;
sub calc {
    my($l, $r) = @_;

    (
        !$l,
        !$r,
        ~$l,
        ~$r,
    );
}

plan tests => $plan * blocks;

run {
    my $block = shift;

    my @simple = calc($block->l, $block->r);
    my @object = calc(Number::Object->new($block->l), Number::Object->new($block->r));

    for my $i (0..($plan-1)) {
        is $simple[$i], $object[$i];
    }
}

__END__

===
--- l
10
--- r
20

===
--- l
20
--- r
20

===
--- l
20
--- r
10

===
--- l
0
--- r
1

===
--- l
1
--- r
0
