use strict;
use warnings;
use Test::Base;

use Number::Object;

filters { l => [qw/ chop /], r => [qw/ chop /] };

my $plan = 10;
sub calc {
    my($l, $r) = @_;
    my @ret;
    my $tmp;

    $tmp = $l;
    $tmp += $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp -= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp *= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp /= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp %= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp **= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp <<= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp >>= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp x= $r;
    push @ret, $tmp;

    $tmp = $l;
    $tmp .= $r;
    push @ret, $tmp;

    @ret;
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
