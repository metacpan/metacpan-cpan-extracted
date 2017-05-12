use strict;
use warnings;
use Test::Base;


use Number::Object;

filters { l => [qw/ chop /], r => [qw/ chop /] };

my $plan = 13;
sub calc {
    my($l, $r) = @_;

    (
        atan2($l, $r),
        cos($l),
        cos($r),
        sin($l),
        sin($r),
        exp($l),
        exp($r),
        abs($l),
        abs($r),
        log($l),
        log($r),
        sqrt($l),
        sqrt($r),
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
