#! /usr/bin/env perl

use v5.22;
use warnings;
use strict;

use Object::Pad ':experimental(init_expr)';
use Multi::Dispatch;

class Sequence {
    field $from :param;
    field $to   :param;
    field $step :param {1};

    multimethod of :common ($to) {
        $class->new(from=>0, to=>$to-1);
    }

    multimethod of :common ($from, $to) {
        $class->new(from=>$from, to=>$to);
    }

    multimethod of :common ($from, $then, $to) {
        $class->new(from=>$from, to=>$to, step=>$then-$from);
    }

    method reify {
        my @seq;
        for (my $next=$from; $next <= $to; $next += $step) {
            push @seq, $next;
        }
        return @seq;
    }
}

say join ', ', Sequence->of(10)->reify;           # 0..9
say join ', ', Sequence->of(1, 9)->reify;         # 1..9
say join ', ', Sequence->of(1, 3, 9)->reify;      # 1, 3, 5, 7, 9

