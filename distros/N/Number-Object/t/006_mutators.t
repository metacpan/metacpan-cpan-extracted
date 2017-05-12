use strict;
use warnings;
use Test::Base;

use Number::Object;

plan skip_all => "it has no good idea of test";

filters { l => [qw/ chop /], r => [qw/ chop /] };

my $plan = 8;
sub calc {
    my($l, $r) = @_;
    my @ret;
    my @tmp = ($l, $r, $l, $r, $l, $r, $l, $r);

    eval { $tmp[0]++ }; push @ret, $@;
    eval { $tmp[1]++ }; push @ret, $@;
    eval { ++$tmp[2] }; push @ret, $@;
    eval { ++$tmp[3] }; push @ret, $@;
    eval { $tmp[4]-- }; push @ret, $@;
    eval { $tmp[5]-- }; push @ret, $@;
    eval { --$tmp[6] }; push @ret, $@;
    eval { --$tmp[7] }; push @ret, $@;

    @ret;
}

plan tests => $plan * blocks;

run {
    my $block = shift;

    my @simple = (
        ('"++"(mutators) is unsupported operation') x 4,
        ('"--"(mutators) is unsupported operation') x 4,
    );
    my @object = calc(Number::Object->new($block->l), Number::Object->new($block->r));

    for my $i (0..($plan-1)) {
        my $re = quotemeta $simple[$i];
        like $object[$i], qr/$re/;
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
