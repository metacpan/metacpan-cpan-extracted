#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

multi seq($to) {
    return 0..$to-1;
}

multi seq($from, $to) {
    return $from..$to;
}

multi seq($from, $to :where({$from > $to}) ) {
    return reverse $to..$from;
}

multi seq($from, $then, $to) {
    my $step = $then - $from;
    return map { $from + $step * $_ } 0..abs( ($to-$from)/$step );
}

say join ', ', seq(10);
say join ', ', seq(1,10);
say join ', ', seq(1,3,10);
say join ', ', seq(10,1);
